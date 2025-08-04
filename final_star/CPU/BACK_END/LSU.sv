`include "../defs.svh"

module LSU (
    input                   clk,
    input                   rst,
    input                   flush_back,
    input                   flush_lsu_out,
    input                   stall_mem_request,
    input                   stall_lsuq,
    output                  full_dfifo,

    input       [31 : 0]    datax,
    input       [31 : 0]    Addr,
    input       [ 3 : 0]    Conf,
    output  reg [31 : 0]    Result_r,       // 打一拍输出, 不需要输出 buffer

    input       [ 5 : 0]    Pd,
    input                   ready,
    input                   RegWr,
    input       [ 5 : 0]    tag_rob,
    input                   has_excp,

    output  reg [ 5 : 0]    Pd_r,
    output  reg             ready_r,
    output  reg             RegWr_r,
    output  reg [ 5 : 0]    tag_rob_r,
    output  reg             has_excp_r,
    output  reg             excp_level,     // 1: 地址未对齐 ALE, 0: 地址错误 ADEM

    // from ROB
    input                   isStore_rob,    // 与 isBranch 一样, 都经过 ROB 提交处的掩码
    // to/from DMEM
    output                  MemWr_dmem,
    output                  MemRd_dmem,
    output      [31 : 0]    data_in_dmem,
    output      [31 : 0]    Addr_dmem,
    output      [ 3 : 0]    Conf_dmem,
    input       [31 : 0]    data_out_dmem
);

    assign  excp_level_temp =   ((Conf == `LDH_CONF || Conf == `STH_CONF || Conf == `LDHU_CONF) && Addr[0] != 1'b0)? 1 :
                                ((Conf == `LDW_CONF || Conf == `STW_CONF) && Addr[1 : 0] != 2'b00)? 1 : 0;
    assign  has_excp_temp   =   has_excp? 1 :
                                ((Conf == `LDH_CONF || Conf == `STH_CONF || Conf == `LDHU_CONF) && Addr[0] != 1'b0)? 1 :
                                ((Conf == `LDW_CONF || Conf == `STW_CONF) && Addr[1 : 0] != 2'b00)? 1 :
                                (Addr < `DMEM_MIN || Addr > `DMEM_MAX)? 1 : 0;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            {Pd_r, ready_r, RegWr_r, tag_rob_r, has_excp_r, excp_level}     <=  '0;
        end
        else begin
            if (flush_back | flush_lsu_out) begin
                {Pd_r, ready_r, RegWr_r, tag_rob_r, has_excp_r, excp_level} <=  '0;
            end
            else begin
                {Pd_r, ready_r, RegWr_r, tag_rob_r, has_excp_r, excp_level} <=  {Pd, ready, RegWr, tag_rob, has_excp_temp, excp_level_temp};
            end
        end
    end

    typedef struct packed {
        reg     [31 : 0]    data;
        reg     [31 : 0]    Addr;
        reg     [ 3 : 0]    Conf;
        reg                 need_store;
    } dfifo_entry;

    dfifo_entry         dfifo_list      [15 : 0];

    reg     [15 : 0]    ready_dfifo;

    reg     [ 3 : 0]    ptr_old;
    reg     [ 3 : 0]    ptr_young;
    reg     [ 3 : 0]    ptr_wait;

    // generate "nearly-full" signal
    assign  full_dfifo  =   (ready_dfifo == 16'h7fff) || (ready_dfifo == 16'hbfff) || (ready_dfifo == 16'hdfff) || (ready_dfifo == 16'hefff) ||
                            (ready_dfifo == 16'hf7ff) || (ready_dfifo == 16'hfbff) || (ready_dfifo == 16'hfdff) || (ready_dfifo == 16'hfeff) ||
                            (ready_dfifo == 16'hff7f) || (ready_dfifo == 16'hffbf) || (ready_dfifo == 16'hffdf) || (ready_dfifo == 16'hffef) ||
                            (ready_dfifo == 16'hfff7) || (ready_dfifo == 16'hfffb) || (ready_dfifo == 16'hfffd) || (ready_dfifo == 16'hfffe) ||
                            (ready_dfifo == 16'hffff)? 1 : 0;

    // search latest LOAD in dfifo
    reg     [31 : 0]    Addr_search         [3 : 0];
    reg     [ 7 : 0]    data_dfifo          [3 : 0];
    reg                 find_in_dfifo       [3 : 0];
    reg     [15 : 0]    dfifo_match_list    [3 : 0];
    reg     [ 3 : 0]    match_entry         [3 : 0];
    wire                find_in_fifo_total;

    integer             temp_j              [3 : 0];

    generate
        for (genvar k = 0; k < 4; k = k + 1) begin
            always @(*) begin
                Addr_search[k]  =   Addr + k;
                for (integer i = 0; i < 16; i = i + 1) begin
                    temp_j[k] = (i + ptr_old) & 32'd15;
                    dfifo_match_list[k][i] = (ready_dfifo[temp_j[k]] == 1 &&
                    ((dfifo_list[temp_j[k]].Conf == `STB_CONF && dfifo_list[temp_j[k]].Addr == Addr_search[k]) ||
                     (dfifo_list[temp_j[k]].Conf == `STH_CONF && dfifo_list[temp_j[k]].Addr > Addr_search[k]-2 && dfifo_list[temp_j[k]].Addr <= Addr_search[k]) ||
                     (dfifo_list[temp_j[k]].Conf == `STW_CONF && dfifo_list[temp_j[k]].Addr > Addr_search[k]-4 && dfifo_list[temp_j[k]].Addr <= Addr_search[k])))? 1 : 0;
                end

                casez (dfifo_match_list[k])
                    16'b1???_????_????_????:    {match_entry[k], find_in_dfifo[k]}    =   {4'd15, 1'b1};
                    16'b01??_????_????_????:    {match_entry[k], find_in_dfifo[k]}    =   {4'd14, 1'b1};
                    16'b001?_????_????_????:    {match_entry[k], find_in_dfifo[k]}    =   {4'd13, 1'b1};
                    16'b0001_????_????_????:    {match_entry[k], find_in_dfifo[k]}    =   {4'd12, 1'b1};
                    16'b0000_1???_????_????:    {match_entry[k], find_in_dfifo[k]}    =   {4'd11, 1'b1};
                    16'b0000_01??_????_????:    {match_entry[k], find_in_dfifo[k]}    =   {4'd10, 1'b1};
                    16'b0000_001?_????_????:    {match_entry[k], find_in_dfifo[k]}    =   {4'd9 , 1'b1};
                    16'b0000_0001_????_????:    {match_entry[k], find_in_dfifo[k]}    =   {4'd8 , 1'b1};

                    16'b0000_0000_1???_????:    {match_entry[k], find_in_dfifo[k]}    =   {4'd7 , 1'b1};
                    16'b0000_0000_01??_????:    {match_entry[k], find_in_dfifo[k]}    =   {4'd6 , 1'b1};
                    16'b0000_0000_001?_????:    {match_entry[k], find_in_dfifo[k]}    =   {4'd5 , 1'b1};
                    16'b0000_0000_0001_????:    {match_entry[k], find_in_dfifo[k]}    =   {4'd4 , 1'b1};
                    16'b0000_0000_0000_1???:    {match_entry[k], find_in_dfifo[k]}    =   {4'd3 , 1'b1};
                    16'b0000_0000_0000_01??:    {match_entry[k], find_in_dfifo[k]}    =   {4'd2 , 1'b1};
                    16'b0000_0000_0000_001?:    {match_entry[k], find_in_dfifo[k]}    =   {4'd1 , 1'b1};
                    16'b0000_0000_0000_0001:    {match_entry[k], find_in_dfifo[k]}    =   {4'd0 , 1'b1};

                    default:                    {match_entry[k], find_in_dfifo[k]}    =   {4'd0 , 1'b0};
                endcase

                if (match_entry[k] + ptr_old >= 16) begin
                    data_dfifo[k]   =   dfifo_list[match_entry[k] + ptr_old - 16].Conf == `STB_CONF?            dfifo_list[match_entry[k] + ptr_old - 16].data[ 7: 0]  :
                                        dfifo_list[match_entry[k] + ptr_old - 16].Conf == `STH_CONF?
                                       (dfifo_list[match_entry[k] + ptr_old - 16].Addr == Addr_search[k]?       dfifo_list[match_entry[k] + ptr_old - 16].data[ 7: 0]  :
                                                                                                                dfifo_list[match_entry[k] + ptr_old - 16].data[15: 8]) :
                                        dfifo_list[match_entry[k] + ptr_old - 16].Addr == Addr_search[k]?       dfifo_list[match_entry[k] + ptr_old - 16].data[ 7: 0]  :
                                        dfifo_list[match_entry[k] + ptr_old - 16].Addr == Addr_search[k]-1?     dfifo_list[match_entry[k] + ptr_old - 16].data[15: 8]  :
                                        dfifo_list[match_entry[k] + ptr_old - 16].Addr == Addr_search[k]-2?     dfifo_list[match_entry[k] + ptr_old - 16].data[23:16]  :
                                        dfifo_list[match_entry[k] + ptr_old - 16].Addr == Addr_search[k]-3?     dfifo_list[match_entry[k] + ptr_old - 16].data[31:24]  : '0;
                end
                else begin
                    data_dfifo[k]   =   dfifo_list[match_entry[k] + ptr_old].Conf == `STB_CONF?                 dfifo_list[match_entry[k] + ptr_old].data[ 7: 0]        :
                                        dfifo_list[match_entry[k] + ptr_old].Conf == `STH_CONF?         
                                       (dfifo_list[match_entry[k] + ptr_old].Addr == Addr_search[k]?            dfifo_list[match_entry[k] + ptr_old].data[ 7: 0]        :
                                                                                                                dfifo_list[match_entry[k] + ptr_old].data[15: 8])       :
                                        dfifo_list[match_entry[k] + ptr_old].Addr == Addr_search[k]?            dfifo_list[match_entry[k] + ptr_old].data[ 7: 0]        :
                                        dfifo_list[match_entry[k] + ptr_old].Addr == Addr_search[k]-1?          dfifo_list[match_entry[k] + ptr_old].data[15: 8]        :
                                        dfifo_list[match_entry[k] + ptr_old].Addr == Addr_search[k]-2?          dfifo_list[match_entry[k] + ptr_old].data[23:16]        :
                                        dfifo_list[match_entry[k] + ptr_old].Addr == Addr_search[k]-3?          dfifo_list[match_entry[k] + ptr_old].data[31:24]        : '0;
                end
            end
        end
    endgenerate

    assign  find_in_fifo_total  =   (Conf == `LDB_CONF || Conf == `LDBU_CONF)?  find_in_dfifo[0] :
                                    (Conf == `LDH_CONF || Conf == `LDHU_CONF)?  find_in_dfifo[0] & find_in_dfifo[1] :
                                                                                find_in_dfifo[0] & find_in_dfifo[1] & find_in_dfifo[2] & find_in_dfifo[3];

    // commit 1 STORE
    // wire    [ 3 : 0]    Conf_dmem;
    wire    [31 : 0]    Addr_write_dmem;
    // wire    [31 : 0]    data_in_dmem;
    // wire                MemWr_dmem;
    // wire                MemRd_dmem;
    // dcache_lock? MemWr_0 : 
// dcache_lock? MemRd_0 : 

    reg     MemWr_0;
    reg     MemRd_0;
    reg     dcache_lock;

    assign  MemWr_dmem      =   dcache_lock? MemWr_0 : !MemRd_dmem & dfifo_list[ptr_old].need_store;
    assign  MemRd_dmem      =   dcache_lock? MemRd_0 : !has_excp_temp & ready & RegWr & !find_in_fifo_total;
    assign  data_in_dmem    =   dfifo_list[ptr_old].data;
    assign  Addr_write_dmem =   dfifo_list[ptr_old].Addr;
    assign  Conf_dmem       =   dfifo_list[ptr_old].Conf;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            MemWr_0 <= 0;
            MemRd_0 <= 0;
            dcache_lock <= 0;
        end
        else begin
            if (stall_mem_request) begin
                MemWr_0 <= MemWr_dmem;
                MemRd_0 <= MemRd_dmem;
                dcache_lock <= 1;
            end
            else begin
                MemWr_0 <= 0;
                MemRd_0 <= 0;
                dcache_lock <= 0;
            end
        end
    end

    // LOAD DMEM and select
    reg     [ 7 : 0]    data_dfifo_r        [3 : 0];
    reg                 find_in_dfifo_r     [3 : 0];
    reg     [ 3 : 0]    Conf_r;

    wire    [31 : 0]    Addr_read_dmem;
    // wire    [31 : 0]    data_out_dmem;
    wire    [31 : 0]    Result_temp;

    assign  Addr_read_dmem      =   Addr;
    assign  Addr_dmem           =   MemWr_dmem? Addr_write_dmem : Addr_read_dmem;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (integer i = 0; i < 16; i = i + 1) begin
                dfifo_list[i]           <=  '0;
            end
            ready_dfifo                 <=  '0;
            ptr_old                     <=  '0;
            ptr_young                   <=  '0;
            ptr_wait                    <=  '0;
            for (integer i = 0; i < 4; i = i + 1) begin
                data_dfifo_r[i]         <=  '0;
                find_in_dfifo_r[i]      <=  '0;
            end
            Conf_r                      <=  '0;
        end
        else begin
            if (flush_back) begin
                for (integer i = 0; i < 16; i = i + 1) begin
                    if (!(dfifo_list[i].need_store || (i == ptr_wait && isStore_rob))) begin
                        dfifo_list[i]   <=  '0;
                        ready_dfifo[i]  <=  '0;
                    end
                end
                ptr_young               <=  isStore_rob? ptr_wait + 1 : ptr_wait;
                for (integer i = 0; i < 4; i = i + 1) begin
                    data_dfifo_r[i]     <=  '0;
                    find_in_dfifo_r[i]  <=  '0;
                end
                Conf_r                  <=  '0;
            end
            else begin
                if (ready) begin
                    // LOAD from DMEM
                    for (integer i = 0; i < 4; i = i + 1) begin
                        data_dfifo_r[i]     <=  RegWr? data_dfifo[i] : '0;
                        find_in_dfifo_r[i]  <=  RegWr? find_in_dfifo[i] : '0;
                    end
                    Conf_r                  <=  RegWr? Conf : '0;
                    // STORE in dfifo
                    if ((Conf == `STB_CONF || Conf == `STH_CONF || Conf == `STW_CONF) && !has_excp_temp && !stall_lsuq) begin
                        dfifo_list[ptr_young]   <=  {datax, Addr, Conf, 1'b0};
                        ready_dfifo[ptr_young]  <=  1;
                        ptr_young               <=  ptr_young + 1;
                    end
                end
            end

            // awake 1 STORE
            if (isStore_rob) begin
                dfifo_list[ptr_wait].need_store <=  1;
                ptr_wait                        <=  ptr_wait + 1;
            end
            // commit 1 STORE when no LOAD
            if (!MemRd_dmem && MemWr_dmem && !stall_mem_request) begin
                dfifo_list[ptr_old]     <=  '0;
                ready_dfifo[ptr_old]    <=  0;
                ptr_old                 <=  ptr_old + 1;
            end
        end
    end


    reg     [ 1 : 0]    Addr_sel;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            Addr_sel    <=  '0;
        end
        else begin
            Addr_sel    <=  Addr[1:0];
        end
    end

    wire    [ 7 : 0]    data_8;
    wire    [15 : 0]    data_16;

    // always @(*) begin
    //     case (Addr_sel)
    //         2'b00:  begin   data_8  =   Result_temp[ 7: 0]; data_16 =   Result_temp[15: 0]; end
    //         2'b01:  begin   data_8  =   Result_temp[15: 8]; data_16 =   Result_temp[15: 0]; end
    //         2'b10:  begin   data_8  =   Result_temp[23:16]; data_16 =   Result_temp[31:16]; end
    //         2'b11:  begin   data_8  =   Result_temp[31:24]; data_16 =   Result_temp[31:16]; end
    //     endcase
    // end

    // always @(*) begin
    //     case (Addr_sel)
    //         2'b00: begin
    //             Result_temp[ 7: 0]  =   find_in_dfifo_r[0]? data_dfifo_r[0] : data_out_dmem[ 7: 0];
    //             Result_temp[15: 8]  =   find_in_dfifo_r[1]? data_dfifo_r[1] : data_out_dmem[15: 8];
    //             Result_temp[23:16]  =   find_in_dfifo_r[2]? data_dfifo_r[2] : data_out_dmem[23:16];
    //             Result_temp[31:24]  =   find_in_dfifo_r[3]? data_dfifo_r[3] : data_out_dmem[31:24];
    //         end
    //         2'b01: begin
    //             Result_temp[15: 8]  =   find_in_dfifo_r[0]? data_dfifo_r[0] : data_out_dmem[ 7: 0];
    //             Result_temp[23:16]  =   find_in_dfifo_r[1]? data_dfifo_r[1] : data_out_dmem[15: 8];
    //             Result_temp[31:24]  =   find_in_dfifo_r[2]? data_dfifo_r[2] : data_out_dmem[23:16];
    //             Result_temp[ 7: 0]  =   find_in_dfifo_r[3]? data_dfifo_r[3] : data_out_dmem[31:24];
    //         end
    //         2'b10: begin
    //             Result_temp[23:16]  =   find_in_dfifo_r[0]? data_dfifo_r[0] : data_out_dmem[ 7: 0];
    //             Result_temp[31:24]  =   find_in_dfifo_r[1]? data_dfifo_r[1] : data_out_dmem[15: 8];
    //             Result_temp[ 7: 0]  =   find_in_dfifo_r[2]? data_dfifo_r[2] : data_out_dmem[23:16];
    //             Result_temp[15: 8]  =   find_in_dfifo_r[3]? data_dfifo_r[3] : data_out_dmem[31:24];
    //         end
    //         2'b11: begin
    //             Result_temp[31:24]  =   find_in_dfifo_r[0]? data_dfifo_r[0] : data_out_dmem[ 7: 0];
    //             Result_temp[ 7: 0]  =   find_in_dfifo_r[1]? data_dfifo_r[1] : data_out_dmem[15: 8];
    //             Result_temp[15: 8]  =   find_in_dfifo_r[2]? data_dfifo_r[2] : data_out_dmem[23:16];
    //             Result_temp[23:16]  =   find_in_dfifo_r[3]? data_dfifo_r[3] : data_out_dmem[31:24];
    //         end
    //     endcase
    // end

    // assign  Result_temp[ 7: 0]  =   find_in_dfifo_r[0]? data_dfifo_r[0] : data_out_dmem[ 7: 0];
    // assign  Result_temp[15: 8]  =   find_in_dfifo_r[1]? data_dfifo_r[1] : data_out_dmem[15: 8];
    // assign  Result_temp[23:16]  =   find_in_dfifo_r[2]? data_dfifo_r[2] : data_out_dmem[23:16];
    // assign  Result_temp[31:24]  =   find_in_dfifo_r[3]? data_dfifo_r[3] : data_out_dmem[31:24];

    reg     [ 7 : 0]    data_mem    [3 : 0];
    always @(*) begin
        case (Addr_sel)
            2'b00:  begin
                data_mem[0] = data_out_dmem[ 7: 0];
                data_mem[1] = data_out_dmem[15: 8];
                data_mem[2] = data_out_dmem[23:16];
                data_mem[3] = data_out_dmem[31:24];
            end
            2'b01:  begin
                data_mem[0] = data_out_dmem[15: 8];
                data_mem[1] = data_out_dmem[23:16];
                data_mem[2] = data_out_dmem[31:24];
                data_mem[3] = '0;
            end
            2'b10:  begin
                data_mem[0] = data_out_dmem[23:16];
                data_mem[1] = data_out_dmem[31:24];
                data_mem[2] = '0;
                data_mem[3] = '0;
            end
            2'b11:  begin
                data_mem[0] = data_out_dmem[31:24];
                data_mem[1] = '0;
                data_mem[2] = '0;
                data_mem[3] = '0;
            end
        endcase
    end

    assign  Result_temp[ 7: 0]  =   find_in_dfifo_r[0]? data_dfifo_r[0] : data_mem[0];
    assign  Result_temp[15: 8]  =   find_in_dfifo_r[1]? data_dfifo_r[1] : data_mem[1];
    assign  Result_temp[23:16]  =   find_in_dfifo_r[2]? data_dfifo_r[2] : data_mem[2];
    assign  Result_temp[31:24]  =   find_in_dfifo_r[3]? data_dfifo_r[3] : data_mem[3];

    assign  data_8  =   Result_temp[ 7:0];
    assign  data_16 =   Result_temp[15:0];

    reg     [31 : 0]    Addr_r;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            Addr_r  <=  '0;
        end
        else begin
            Addr_r  <=  Addr;
        end
    end

    always @(*) begin
        casez (Conf_r)
            `LDB_CONF:  Result_r    =   has_excp_r? Addr_r : {{24{data_8[7]}}, data_8};
            `LDH_CONF:  Result_r    =   has_excp_r? Addr_r : {{16{data_16[15]}}, data_16};
            `LDW_CONF:  Result_r    =   has_excp_r? Addr_r : Result_temp;
            `LDBU_CONF: Result_r    =   has_excp_r? Addr_r : {24'b0, data_8};
            `LDHU_CONF: Result_r    =   has_excp_r? Addr_r : {16'b0, data_16};
            default:    Result_r    =   has_excp_r? Addr_r : '0;
        endcase
    end

endmodule