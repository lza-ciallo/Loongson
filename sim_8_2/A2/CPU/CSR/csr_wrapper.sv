module csr_wrapper (
    input               clk,
    input               rst,
    input               flush_back,
    output              full_csrfifo,
    input               csrWr_rob,
    //from to ds 
    input   [13 : 0]    rd_addr,
    output  [31 : 0]    rd_data,
    //timer 64
    output  [63 : 0]    timer_64_out,
    output  [31 : 0]    tid_out,
    //from ws
    input               csr_wr_en,
    input   [13 : 0]    wr_addr,
    input   [31 : 0]    wr_data,
    //interrupt
    input   [ 7 : 0]    interrupt,
    output              has_int,
    //from ROB
    input               excp_flush,
    input               ertn_flush,
    input   [31 : 0]    era_in,
    input   [ 4 : 0]    excp_code_rob,
    //to fs
    output  [31 : 0]    eentry_out,
    output  [31 : 0]    era_out,
    //general use
    output  [ 1 : 0]    plv_out
);

    reg                 csrWr_commit;
    reg     [13 : 0]    csrWr_addr_commit;
    reg     [31 : 0]    csrWr_data_commit;

    typedef struct packed {
        reg             csrWr;
        reg [13 : 0]    csrWr_addr;
        reg [31 : 0]    csrWr_data;
    } csrfifo_entry;

    csrfifo_entry   csrfifo     [15 : 0];

    reg     [ 3 : 0]    ptr_old;
    reg     [ 3 : 0]    ptr_young;

    assign  full_csrfifo    =   (ptr_old == ptr_young && csrfifo[ptr_old].csrWr == 1)? 1 : 0;

    // search latest csrWr in csrfifo
    wire                find_in_fifo;
    wire    [31 : 0]    data_fifo;
    wire    [31 : 0]    data_csr;

    fifo_searcher u_fifo_searcher (
        .csrfifo            (csrfifo),
        .ptr_old            (ptr_old),
        .rd_addr            (rd_addr),
        .find_in_fifo       (find_in_fifo),
        .data_fifo          (data_fifo)
    );

    assign  rd_data =   find_in_fifo? data_fifo : data_csr;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (integer i = 0; i < 16; i = i + 1) begin
                csrfifo[i]      <=  '0;
            end
            ptr_old             <=  '0;
            ptr_young           <=  '0;
            {csrWr_commit, csrWr_addr_commit, csrWr_data_commit}            <=  '0;
        end
        else begin
            if (flush_back) begin
                for (integer i = 0; i < 16; i = i + 1) begin
                    csrfifo[i]  <=  '0;
                end
                ptr_old         <=  '0;
                ptr_young       <=  '0;
                {csrWr_commit, csrWr_addr_commit, csrWr_data_commit}        <=  '0;
            end
            else begin
                if (csr_wr_en & ~full_csrfifo) begin
                    csrfifo[ptr_young]  <=  {csr_wr_en, wr_addr, wr_data};
                    ptr_young           <=  ptr_young + 1;
                end

                if (csrWr_rob) begin
                    {csrWr_commit, csrWr_addr_commit, csrWr_data_commit}    <=  csrfifo[ptr_old];
                    csrfifo[ptr_old]                                        <=  '0;
                    ptr_old                                                 <=  ptr_old + 1;
                end
                else begin
                    {csrWr_commit, csrWr_addr_commit, csrWr_data_commit}    <=  '0;
                end
            end
        end
    end

    // eentry, era, plv 也需要 search 一下旁路逻辑
    wire    [31 : 0]    eentry_csr;
    wire    [31 : 0]    eentry_fifo;
    wire                find_eentry;

    wire    [31 : 0]    era_csr;
    wire    [31 : 0]    era_fifo;
    wire                find_era;

    wire    [ 1 : 0]    plv_csr;
    wire    [31 : 0]    plv_fifo;
    wire                find_plv;

    fifo_searcher u_eentry_searcher (
        .csrfifo            (csrfifo),
        .ptr_old            (ptr_old),
        .rd_addr            (14'hc),
        .find_in_fifo       (find_eentry),
        .data_fifo          (eentry_fifo)
    );

    fifo_searcher u_era_searcher (
        .csrfifo            (csrfifo),
        .ptr_old            (ptr_old),
        .rd_addr            (14'h6),
        .find_in_fifo       (find_era),
        .data_fifo          (era_fifo)
    );

    fifo_searcher u_plv_searcher (
        .csrfifo            (csrfifo),
        .ptr_old            (ptr_old),
        .rd_addr            (14'h0),
        .find_in_fifo       (find_plv),
        .data_fifo          (plv_fifo)
    );

    assign  eentry_out  =   find_eentry?    {eentry_fifo[31:6], 6'b0}   : eentry_csr;
    assign  era_out     =   find_era?       era_fifo                    : era_csr;
    assign  plv_out     =   find_plv?       plv_fifo[1:0]               : plv_csr;

    // write in excp code
    wire    [ 8 : 0]    esubcode_in;
    wire    [ 5 : 0]    ecode_in;
    assign  esubcode_in =   {8'b0, excp_code_rob[0]};
    assign  ecode_in    =   {2'b0, excp_code_rob[4:1]};

    csr u_csr (
        .clk            (clk),
        .reset          (~rst),     // 注意 csr 内部是 if (reset) begin, 与 rst 不同
        //from to ds 
        .rd_addr        (rd_addr),
        .rd_data        (data_csr),
        //timer 64
        .timer_64_out   (timer_64_out),
        .tid_out        (tid_out),
        //from ws
        .csr_wr_en      (csrWr_commit),
        .wr_addr        (csrWr_addr_commit),
        .wr_data        (csrWr_data_commit),
        //interrupt
        .interrupt      (interrupt),
        .has_int        (has_int),
        //from ws
        .excp_flush     (excp_flush),
        .ertn_flush     (ertn_flush),
        .era_in         (era_in),
        .esubcode_in    (esubcode_in),
        .ecode_in       (ecode_in),
        .va_error_in    (1'b0),
        .bad_va_in      (32'b0),
        .tlbsrch_en     (1'b0),
        .tlbsrch_found  (1'b0),
        .tlbsrch_index  (5'b0),
        .excp_tlbrefill (1'b0),
        .excp_tlb       (1'b0),
        .excp_tlb_vppn  (19'b0),
        //from ws llbit
        .llbit_in       (1'b0),//!
        .llbit_set_in   (1'b0),
        .lladdr_in      (28'b0),
        .lladdr_set_in  (1'b0),
        //to es
        // output                          llbit_out    ,
        // output [18:0]                   vppn_out     ,
        //to ms
        // output [27:0]                   lladdr_out   ,
        //to fs
        .eentry_out     (eentry_csr),
        .era_out        (era_csr),
        // output [31:0]                   tlbrentry_out,
        // output                          disable_cache_out,
        //to addr trans
        // output [ 9:0]                   asid_out     ,
        // output [ 4:0]                   rand_index   ,
        // output [31:0]                   tlbehi_out   ,
        // output [31:0]                   tlbelo0_out  ,
        // output [31:0]                   tlbelo1_out  ,
        // output [31:0]                   tlbidx_out   ,
        // output                          pg_out       ,
        // output                          da_out       ,
        // output [31:0]                   dmw0_out     ,
        // output [31:0]                   dmw1_out     ,
        // output [ 1:0]                   datf_out     ,
        // output [ 1:0]                   datm_out     ,
        // output [ 5:0]                   ecode_out    ,
        //from addr trans 
        .tlbrd_en       (1'b0),
        .tlbehi_in      (32'b0),
        .tlbelo0_in     (32'b0),
        .tlbelo1_in     (32'b0),
        .tlbidx_in      (32'b0),
        .asid_in        (10'b0),
        //general use
        .plv_out        (plv_csr)
    );
    
endmodule