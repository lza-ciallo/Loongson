`include "../defs.svh"

module DIRQ (
    input                   clk,
    input                   rst,
    input                   flush_dirq,
    input                   stall_in,
    output                  full_dirq,

    input                   ready_pc[2 : 0],
    input       [ 2 : 0]    Type    [2 : 0],
    input       [ 3 : 0]    Conf    [2 : 0],
    input       [31 : 0]    imm     [2 : 0],
    input       [31 : 0]    pc      [2 : 0],    // 专为 JIRL 所设
    input       [ 5 : 0]    Pd      [2 : 0],
    input                   RegWr   [2 : 0],

    output  reg             ready_awake,
    output  reg [31 : 0]    imm_awake,
    output  reg [ 5 : 0]    Pd_awake,
    output  reg             RegWr_awake,
    output  reg [ 3 : 0]    Conf_awake,
    output  reg [ 5 : 0]    tag_rob_awake,
    output  reg             isJIRL_awake,

    // from ROB
    input       [ 5 : 0]    tag_rob [2 : 0]
);

    typedef struct packed {
        reg     [31 : 0]    imm;
        reg     [ 5 : 0]    Pd;
        reg                 RegWr;
        reg     [ 3 : 0]    Conf;
        reg     [ 5 : 0]    tag_rob;
        reg                 isJIRL;
    } dirq_entry;

    dirq_entry          dirq_list   [15 : 0];

    reg     [15 : 0]    ready_list;

    reg     [ 3 : 0]    ptr_old;
    reg     [ 3 : 0]    ptr_young;

    wire    [ 3 : 0]    ptr_write   [ 2 : 0];
    assign  ptr_write[0]    =   ptr_young;
    assign  ptr_write[1]    =   ptr_young + 1;
    assign  ptr_write[2]    =   ptr_young + 2;

    assign  full_dirq       =   ((ptr_write[0] == ptr_old || ptr_write[1] == ptr_old || ptr_write[2] == ptr_old) &&
                                (ready_list[ptr_old] == 1))? 1 : 0;

    // 为密堆积预加载一层掩膜
    wire    [ 2 : 0]    token;
    reg     [ 1 : 0]    index       [ 2 : 0];
    wire    [ 2 : 0]    mask;
    generate
        for (genvar i = 0; i < 3; i = i + 1) begin
            assign  token[i]    =   ((Type[i] == `DIR_TYPE || Type[i] == `JIRL_TYPE) && ready_pc[i])? 1 : 0;
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
            for (integer i = 0; i < 16; i = i + 1) begin
                dirq_list[i]                    <=  '0;
            end
            ready_awake                         <=  '0;
            {imm_awake, Pd_awake, RegWr_awake, Conf_awake,
                tag_rob_awake, isJIRL_awake}    <=  '0;
            ptr_old                             <=  '0;
            ptr_young                           <=  '0;
        end
        else begin
            if (flush_dirq) begin
                ready_list                      <=  '0;
                for (integer i = 0; i < 16; i = i + 1) begin
                    dirq_list[i]                <=  '0;
                end
                {imm_awake, Pd_awake, RegWr_awake, Conf_awake,
                    tag_rob_awake, isJIRL_awake}<=  '0;
                ptr_old                         <=  '0;
                ptr_young                       <=  '0;
            end
            else begin
                if (!full_dirq && !stall_in) begin
                    // 完全先进先出, 采用密堆积
                    for (integer i = 0; i < 3; i = i + 1) begin
                        if (index[i] != 3) begin
                            ready_list[ptr_write[i]]    <=  1;
                            dirq_list[ptr_write[i]]     <=  (Type[index[i]] == `JIRL_TYPE)?
                                                            {pc[index[i]]+4, Pd[index[i]], RegWr[index[i]], Conf[index[i]], tag_rob[index[i]], 1'b1} :
                                                            {imm[index[i]], Pd[index[i]], RegWr[index[i]], Conf[index[i]], tag_rob[index[i]], 1'b0};
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
                if (ready_list[ptr_old] == 1) begin
                    ready_awake                         <=  ready_list[ptr_old];
                    {imm_awake, Pd_awake, RegWr_awake, Conf_awake,
                        tag_rob_awake, isJIRL_awake}    <=  dirq_list[ptr_old];
                    ready_list[ptr_old]                 <=  '0;
                    dirq_list[ptr_old]                  <=  '0;
                    ptr_old                             <=  ptr_old + 1;
                end
                else begin
                    ready_awake                         <=  '0;
                    {imm_awake, Pd_awake, RegWr_awake, Conf_awake,
                        tag_rob_awake, isJIRL_awake}    <=  '0;
                end
            end
        end
    end

endmodule