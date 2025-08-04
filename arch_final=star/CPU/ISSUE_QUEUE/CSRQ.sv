`include "../defs.svh"

module CSRQ (
    input                   clk,
    input                   rst,
    input                   flush_csrq,
    input                   stall_in,
    output                  full_csrq,

    input                   ready_pc        [2 : 0],
    input       [ 2 : 0]    Type            [2 : 0],
    input       [ 3 : 0]    Conf            [2 : 0],
    input       [ 5 : 0]    Pj              [2 : 0],
    input                   valid_Pj        [2 : 0],
    input       [ 5 : 0]    Pd_old          [2 : 0],
    input                   valid_Pd_old    [2 : 0],
    input       [ 5 : 0]    Pd              [2 : 0],
    input                   RegWr           [2 : 0],
    input       [13 : 0]    csr_addr        [2 : 0],
    input                   csrWr           [2 : 0],

    output  reg [ 5 : 0]    tag_rob_awake,
    output  reg [ 3 : 0]    Conf_awake,
    output  reg [ 5 : 0]    Pj_awake,
    output  reg [ 5 : 0]    Pd_old_awake,
    output  reg [ 5 : 0]    Pd_awake,
    output  reg [13 : 0]    csr_addr_awake,
    output  reg             ready_awake,
    output  reg             RegWr_awake,
    output  reg             csrWr_awake,

    // from ROB
    input       [ 5 : 0]    tag_rob     [2 : 0],
    input                   csrWr_rob,

    // from CDB
    input                   ready_cdb   [4 : 0],
    input                   RegWr_cdb   [4 : 0],
    input       [ 5 : 0]    Pd_cdb      [4 : 0]
);

    typedef struct packed {
        reg     [ 5 : 0]    Pj;
        reg     [ 5 : 0]    Pd_old;
        reg     [ 5 : 0]    Pd;
        reg     [13 : 0]    csr_addr;
        reg                 RegWr;
        reg                 csrWr;
        reg     [ 3 : 0]    Conf;
        reg     [ 5 : 0]    tag_rob;
    } csrq_entry;

    csrq_entry  csrq_list   [15 : 0];

    reg     [15 : 0]    ready_list;
    reg     [15 : 0]    ready_Pj_list;
    reg     [15 : 0]    ready_Pd_old_list;

    reg                 enable_issue;       // 实现特权指令的原子性

    reg     [ 3 : 0]    ptr_old;
    reg     [ 3 : 0]    ptr_young;

    wire    [ 3 : 0]    ptr_write   [ 2 : 0];
    assign  ptr_write[0]    =   ptr_young;
    assign  ptr_write[1]    =   ptr_young + 1;
    assign  ptr_write[2]    =   ptr_young + 2;

    assign  full_csrq       =   ((ptr_write[0] == ptr_old || ptr_write[1] == ptr_old || ptr_write[2] == ptr_old) &&
                                (ready_list[ptr_old] == 1))? 1 : 0;

    // 为密堆积预加载一层掩膜
    wire    [ 2 : 0]    token;
    reg     [ 1 : 0]    index       [ 2 : 0];
    wire    [ 2 : 0]    mask;
    generate
        for (genvar i = 0; i < 3; i = i + 1) begin
            assign  token[i]    =   (Type[i] == `CSR_TYPE && ready_pc[i])? 1 : 0;
            assign  mask[i]     =   (index[i] == 3)? 0 : 1;
        end
    endgenerate

    always @(*) begin
        case (token)
            3'b000: {index[2], index[1], index[0]}  =   {2'd3, 2'd3, 2'd3};
            3'b001: {index[2], index[1], index[0]}  =   {2'd3, 2'd3, 2'd0};
            3'b010: {index[2], index[1], index[0]}  =   {2'd3, 2'd3, 2'd1};
            3'b011: {index[2], index[1], index[0]}  =   {2'd3, 2'd1, 2'd0};
            3'b100: {index[2], index[1], index[0]}  =   {2'd3, 2'd3, 2'd2};
            3'b101: {index[2], index[1], index[0]}  =   {2'd3, 2'd2, 2'd0};
            3'b110: {index[2], index[1], index[0]}  =   {2'd3, 2'd2, 2'd1};
            3'b111: {index[2], index[1], index[0]}  =   {2'd2, 2'd1, 2'd0};
        endcase
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            ready_list                          <=  '0;
            ready_Pj_list                       <=  '0;
            ready_Pd_old_list                   <=  '0;
            for (integer i = 0; i < 16; i = i + 1) begin
                csrq_list[i]                    <=  '0;
            end
            ready_awake                         <=  '0;
            {tag_rob_awake, Conf_awake, Pj_awake, Pd_old_awake, Pd_awake, csr_addr_awake,
                RegWr_awake, csrWr_awake}       <=  '0;
            ptr_old                             <=  '0;
            ptr_young                           <=  '0;
            enable_issue                        <=  1;
        end
        else begin
            if (flush_csrq) begin
                ready_list                      <=  '0;
                ready_Pj_list                   <=  '0;
                ready_Pd_old_list               <=  '0;
                for (integer i = 0; i < 16; i = i + 1) begin
                    csrq_list[i]                <=  '0;
                end
                ready_awake                     <=  '0;
                {tag_rob_awake, Conf_awake, Pj_awake, Pd_old_awake, Pd_awake, csr_addr_awake,
                    RegWr_awake, csrWr_awake}   <=  '0;
                ptr_old                         <=  '0;
                ptr_young                       <=  '0;
                enable_issue                    <=  1;
            end
            else begin
                if (!full_csrq && !stall_in) begin
                    // 完全先进先出, 采用密堆积
                    for (integer i = 0; i < 3; i = i + 1) begin
                        if (index[i] != 3) begin
                            ready_list[ptr_write[i]]        <=  1;
                            csrq_list[ptr_write[i]]         <=  (Conf[index[i]] != `CSRXG_CONF && Conf[index[i]] != `CPU_CONF)?
                                                                {6'b0, Pd_old[index[i]], Pd[index[i]], csr_addr[index[i]],
                                                                    RegWr[index[i]], csrWr[index[i]], Conf[index[i]], tag_rob[index[i]]} :
                                                                {Pj[index[i]], Pd_old[index[i]], Pd[index[i]], csr_addr[index[i]],
                                                                    RegWr[index[i]], csrWr[index[i]], Conf[index[i]], tag_rob[index[i]]};
                            ready_Pj_list[ptr_write[i]]     <=  (Conf[index[i]] != `CSRXG_CONF && Conf[index[i]] != `CPU_CONF)? 1 :
                                                                (Pj[index[i]] == Pd_cdb[0] && ready_cdb[0] && RegWr_cdb[0]) ||
                                                                (Pj[index[i]] == Pd_cdb[1] && ready_cdb[1] && RegWr_cdb[1]) ||
                                                                (Pj[index[i]] == Pd_cdb[2] && ready_cdb[2] && RegWr_cdb[2]) ||
                                                                (Pj[index[i]] == Pd_cdb[3] && ready_cdb[3] && RegWr_cdb[3]) ||
                                                                (Pj[index[i]] == Pd_cdb[4] && ready_cdb[4] && RegWr_cdb[4])? 1 : valid_Pj[index[i]];
                            ready_Pd_old_list[ptr_write[i]] <=  (Conf[index[i]] == `CPU_CONF)? 1 :
                                                                (Pd_old[index[i]] == Pd_cdb[0] && ready_cdb[0] && RegWr_cdb[0]) ||
                                                                (Pd_old[index[i]] == Pd_cdb[1] && ready_cdb[1] && RegWr_cdb[1]) ||
                                                                (Pd_old[index[i]] == Pd_cdb[2] && ready_cdb[2] && RegWr_cdb[2]) ||
                                                                (Pd_old[index[i]] == Pd_cdb[3] && ready_cdb[3] && RegWr_cdb[3]) ||
                                                                (Pd_old[index[i]] == Pd_cdb[4] && ready_cdb[4] && RegWr_cdb[4])? 1 : valid_Pd_old[index[i]];
                        end
                    end
                    // 更新 ptr_young
                    case (mask)
                        3'b000: ptr_young   <=  ptr_young;
                        3'b001: ptr_young   <=  ptr_young + 1;
                        3'b011: ptr_young   <=  ptr_young + 2;
                        3'b111: ptr_young   <=  ptr_young + 3;
                    endcase
                end

                // 发射最老的
                if (ready_list[ptr_old] & ready_Pj_list[ptr_old] & ready_Pd_old_list[ptr_old] & enable_issue) begin
                    ready_awake                         <=  ready_list[ptr_old];
                    tag_rob_awake                       <=  csrq_list[ptr_old].tag_rob;
                    Conf_awake                          <=  csrq_list[ptr_old].Conf;
                    Pj_awake                            <=  csrq_list[ptr_old].Pj;
                    Pd_old_awake                        <=  csrq_list[ptr_old].Pd_old;
                    Pd_awake                            <=  csrq_list[ptr_old].Pd;
                    csr_addr_awake                      <=  csrq_list[ptr_old].csr_addr;
                    RegWr_awake                         <=  csrq_list[ptr_old].RegWr;
                    csrWr_awake                         <=  csrq_list[ptr_old].csrWr;
                    ready_list[ptr_old]                 <=  '0;
                    ready_Pj_list[ptr_old]              <=  '0;
                    ready_Pd_old_list[ptr_old]          <=  '0;
                    csrq_list[ptr_old]                  <=  '0;
                    ptr_old                             <=  ptr_old + 1;
                    if (csrq_list[ptr_old].csrWr == 1) begin
                        enable_issue                    <=  0;
                    end
                end
                else begin
                    ready_awake                         <=  '0;
                    {tag_rob_awake, Conf_awake, Pj_awake, Pd_old_awake, Pd_awake, csr_addr_awake,
                        RegWr_awake, csrWr_awake}       <=  '0;
                end


                // CDB
                for (integer i = 0; i < 5; i = i + 1) begin
                    if (ready_cdb[i] && RegWr_cdb[i]) begin
                        for (integer j = 0; j < 16; j = j + 1) begin
                            if (csrq_list[j].Pj == Pd_cdb[i] && ready_list[j] == 1) begin
                                ready_Pj_list[j]        <=  1;
                            end
                            if (csrq_list[j].Pd_old == Pd_cdb[i] && ready_list[j] == 1) begin
                                ready_Pd_old_list[j]    <=  1;
                            end
                        end
                    end
                end
                // 等执行完
                if (csrWr_rob) begin
                    enable_issue    <=  1;
                end
            end
        end
    end

endmodule