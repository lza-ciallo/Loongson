module BPU (
    input               clk,
    input               rst,

    input   [31 : 0]    pc              [3 : 0],
    output              Hit             [3 : 0],
    output              Predict         [3 : 0],
    output  [31 : 0]    target_branch   [3 : 0],
    
    // from ROB
    input               isBranch_rob,
    input               Branch_rob,
    input   [31 : 0]    pc_rob,
    // from predecoder
    input               dontWriteJIRL   [3 : 0],
    input               isBranch        [3 : 0],
    input   [31 : 0]    pc_write        [3 : 0],
    input   [31 : 0]    target_write    [3 : 0],
    // JIRL from ROB
    input               isJIRL_rob,
    input   [31 : 0]    target_rob
);

    reg     [ 1 : 0]    pht             [63: 0];

    typedef struct packed {
        reg             occupied;
        reg [23 : 0]    tag;
        reg [31 : 0]    target;
    } BTB_entry;

    BTB_entry           btb             [63: 0];

    // search in PHT & BTB, no bypass
    generate
        for (genvar i = 0; i < 4; i = i + 1) begin
            assign  Hit[i]              =   (btb[pc[i][7 : 2]].occupied && (btb[pc[i][7 : 2]].tag == pc[i][31 : 8]))? 1 : 0;
            assign  Predict[i]          =   pht[pc[i][7 : 2]][1];
            assign  target_branch[i]    =   btb[pc[i][7 : 2]].target;
        end
    endgenerate

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (integer i = 0; i < 64; i = i + 1) begin
                pht[i]  <=  2'b01;
                btb[i]  <=  '0;
            end
        end
        else begin
            // adapt to ROB result
            if (isBranch_rob) begin
                case (pht[pc_rob[7 : 2]])
                    2'b00:  pht[pc_rob[7 : 2]]  <=  Branch_rob? 2'b01 : 2'b00;
                    2'b01:  pht[pc_rob[7 : 2]]  <=  Branch_rob? 2'b10 : 2'b00;
                    2'b10:  pht[pc_rob[7 : 2]]  <=  Branch_rob? 2'b11 : 2'b01;
                    2'b11:  pht[pc_rob[7 : 2]]  <=  Branch_rob? 2'b11 : 2'b10;
                endcase
                if (isJIRL_rob) begin
                    btb[pc_rob[7 : 2]]          <=  {1'b1, pc_rob[31 : 8], target_rob};
                end
            end
            
            // learn from predecoder
            for (integer i = 0; i < 4; i = i + 1) begin
                if (isBranch[i] & ~dontWriteJIRL[i]) begin
                    btb[pc_write[i][7 : 2]].occupied    <=  1;
                    btb[pc_write[i][7 : 2]].tag         <=  pc_write[i][31 : 8];
                    btb[pc_write[i][7 : 2]].target      <=  target_write[i];
                end
            end
        end
    end

endmodule