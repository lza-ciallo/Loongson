`include "../defs.svh"

module ALU (
    input                   clk,
    input                   rst,
    input                   flush_back,

    input       [31 : 0]    busA,
    input       [31 : 0]    busB,
    input       [ 3 : 0]    Conf,
    output  reg [31 : 0]    Result_r,

    input       [ 5 : 0]    Pd,
    input                   ready,
    input                   RegWr,
    input       [ 5 : 0]    tag_rob,

    output  reg [ 5 : 0]    Pd_r,
    output  reg             ready_r,
    output  reg             RegWr_r,
    output  reg [ 5 : 0]    tag_rob_r
);

    reg         [31 : 0]    Result;

    always @(*) begin
        case (Conf)
            `ADD_CONF:  Result  =   busA + busB;
            `SUB_CONF:  Result  =   busA - busB;
            `SLT_CONF:  Result  =   ($signed(busA) < $signed(busB))? 1 : 0;
            `SLTU_CONF: Result  =   ($unsigned(busA) < $unsigned(busB))? 1 : 0;
            `NOR_CONF:  Result  =   ~(busA | busB);
            `AND_CONF:  Result  =   busA & busB;
            `OR_CONF:   Result  =   busA | busB;
            `XOR_CONF:  Result  =   busA ^ busB;
            `SLL_CONF:  Result  =   busA << busB[4 : 0];
            `SRL_CONF:  Result  =   busA >> busB[4 : 0];
            `SRA_CONF:  Result  =   $signed(busA) >>> busB[4 : 0];
            default:    Result  =   '0;
        endcase
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            {Result_r, Pd_r, ready_r, RegWr_r, tag_rob_r}       <=  '0;
        end
        else begin
            if (flush_back) begin
                {Result_r, Pd_r, ready_r, RegWr_r, tag_rob_r}   <=  '0;
            end
            else begin
                {Result_r, Pd_r, ready_r, RegWr_r, tag_rob_r}   <=  {Result, Pd, ready, RegWr, tag_rob};
            end
        end
    end

endmodule