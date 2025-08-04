module IFIFO (
    input               clk,
    input               rst,
    input               flush_ififo,
    input               stall_ififo,
    output              full_ififo,

    input   [31 : 0]    pc                  [3 : 0],
    input   [31 : 0]    inst                [3 : 0],
    input               isBranch            [3 : 0],
    input               Predict             [3 : 0],
    input   [31 : 0]    target_branch       [3 : 0],
    input               has_excp            [3 : 0],
    input   [ 4 : 0]    excp_code           [3 : 0],
    input               valid_inst          [3 : 0],

    output              ready_pc_out        [2 : 0],
    output  [31 : 0]    pc_out              [2 : 0],
    output  [31 : 0]    inst_out            [2 : 0],
    output              isBranch_out        [2 : 0],
    output              Predict_out         [2 : 0],
    output  [31 : 0]    target_branch_out   [2 : 0],
    output              has_excp_out        [2 : 0],
    output  [ 4 : 0]    excp_code_out       [2 : 0]
);

    reg     [ 4 : 0]    ptr_young;
    reg     [ 4 : 0]    ptr_old;

    typedef struct packed {
        reg             ready;
        reg [31 : 0]    pc;
        reg [31 : 0]    inst;
        reg             isBranch;
        reg             Predict;
        reg [31 : 0]    target_branch;
        reg             has_excp;
        reg [ 4 : 0]    excp_code;
    } ififo_entry;

    ififo_entry         ififo               [31: 0];

    // temporary wire for IFIFO pop in & out
    wire    [ 4 : 0]    ptr_write           [3 : 0];
    wire    [ 4 : 0]    ptr_read            [2 : 0];

    generate
        for (genvar i = 0; i < 4; i = i + 1) begin
            assign  ptr_write[i]            =   ptr_young + i;
        end
        for (genvar i = 0; i < 3; i = i + 1) begin
            assign  ptr_read[i]             =   ptr_old + i;
        end
    endgenerate

    // assign pop out
    generate
        for (genvar i = 0; i < 3; i = i + 1) begin
            assign  ready_pc_out[i]         =   (stall_ififo | ~ififo[ptr_read[i]].ready)? '0 : ififo[ptr_read[i]].ready;
            assign  pc_out[i]               =   (stall_ififo | ~ififo[ptr_read[i]].ready)? '0 : ififo[ptr_read[i]].pc;
            assign  inst_out[i]             =   (stall_ififo | ~ififo[ptr_read[i]].ready)? '0 : ififo[ptr_read[i]].inst;
            assign  isBranch_out[i]         =   (stall_ififo | ~ififo[ptr_read[i]].ready)? '0 : ififo[ptr_read[i]].isBranch;
            assign  Predict_out[i]          =   (stall_ififo | ~ififo[ptr_read[i]].ready)? '0 : ififo[ptr_read[i]].Predict;
            assign  target_branch_out[i]    =   (stall_ififo | ~ififo[ptr_read[i]].ready)? '0 : ififo[ptr_read[i]].target_branch;
            assign  has_excp_out[i]         =   (stall_ififo | ~ififo[ptr_read[i]].ready)? '0 : ififo[ptr_read[i]].has_excp;
            assign  excp_code_out[i]        =   (stall_ififo | ~ififo[ptr_read[i]].ready)? '0 : ififo[ptr_read[i]].excp_code;
        end
    endgenerate

    // full
    assign  full_ififo  =   ((ptr_old == ptr_write[0] || ptr_old == ptr_write[1] || ptr_old == ptr_write[2] || ptr_old == ptr_write[3]) &&
                            // ((ptr_old == ptr_write[4] || ptr_old == ptr_write[5] || ptr_old == ptr_write[6] || ptr_old == ptr_write[7]) &&
                            (ififo[ptr_old].ready == 1))? 1 : 0;

    // assign  real_full  =   ((ptr_old == ptr_write[0] || ptr_old == ptr_write[1] || ptr_old == ptr_write[2] || ptr_old == ptr_write[3]) &&
    //                         (ififo[ptr_old].ready == 1))? 1 : 0;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            ptr_old             <=  '0;
            ptr_young           <=  '0;
            for (integer i = 0; i < 32; i = i + 1) begin
                ififo[i]        <=  '0;
            end
        end
        else begin
            if (flush_ififo) begin
                ptr_old         <=  '0;
                ptr_young       <=  '0;
                for (integer i = 0; i < 32; i = i + 1) begin
                    ififo[i]    <=  '0;
                end
            end
            else begin

                // pop in, according to valid_inst [3 : 0]
                if (!full_ififo) begin
                // if (!real_full) begin
                    for (integer i = 0; i < 4; i = i + 1) begin
                        if (valid_inst[i]) begin
                            ififo[ptr_write[i]].ready           <=  1;
                            ififo[ptr_write[i]].pc              <=  pc[i];
                            ififo[ptr_write[i]].inst            <=  inst[i];
                            ififo[ptr_write[i]].isBranch        <=  isBranch[i];
                            ififo[ptr_write[i]].Predict         <=  Predict[i];
                            ififo[ptr_write[i]].target_branch   <=  target_branch[i];
                            ififo[ptr_write[i]].has_excp        <=  has_excp[i];
                            ififo[ptr_write[i]].excp_code       <=  excp_code[i];
                        end
                    end
                    // renew ptr_young
                    case ({valid_inst[3], valid_inst[2], valid_inst[1], valid_inst[0]})
                        4'b0000:    ptr_young   <=  ptr_young;
                        4'b0001:    ptr_young   <=  ptr_young + 1;
                        4'b0011:    ptr_young   <=  ptr_young + 2;
                        4'b0111:    ptr_young   <=  ptr_young + 3;
                        4'b1111:    ptr_young   <=  ptr_young + 4;
                    endcase
                end

                // pop out, according to ififo[i].ready
                if (!stall_ififo) begin
                    for (integer i = 0; i < 3; i = i + 1) begin
                        if (ififo[ptr_read[i]].ready) begin
                            ififo[ptr_read[i]]  <=  '0;
                        end
                    end
                    // renew ptr_old
                    case({ififo[ptr_read[2]].ready, ififo[ptr_read[1]].ready, ififo[ptr_read[0]].ready})
                        3'b000:     ptr_old     <=  ptr_old;
                        3'b001:     ptr_old     <=  ptr_old + 1;
                        3'b011:     ptr_old     <=  ptr_old + 2;
                        3'b111:     ptr_old     <=  ptr_old + 3;
                    endcase
                end
            end
        end
    end

endmodule