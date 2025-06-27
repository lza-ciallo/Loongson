module ALU (
    input       [31 : 0]    busA_in,
    input       [31 : 0]    busB_in,
    input       [3 : 0]     ALUConf,
    input       [4 : 0]     shamt,
    output  reg [31 : 0]    Result
);
    
    always @(*) begin
        case (ALUConf)
            0:          Result = busA_in + busB_in;
            1:          Result = busA_in + busB_in;
            2:          Result = busA_in - busB_in;
            3:          Result = busA_in - busB_in;
            4:          Result = busA_in & busB_in;
            5:          Result = busA_in | busB_in;
            6:          Result = busA_in ^ busB_in;
            7:          Result = ~(busA_in | busB_in);
            8:          Result = busB_in << shamt;
            9:          Result = busB_in >>> shamt;
            10:         Result = busB_in >> shamt;
            11:         Result = (busA_in < busB_in)? 32'd1 : 32'd0;
            12:         Result = ({1'b0, busA_in} < {1'b0, busB_in})? 32'd1 : 32'd0;
            // 13:         Result = busA_in * busB_in;
            default:    Result = 32'h0000_0000;
        endcase
    end

endmodule


module MUL_UNIT_A #(
    // parameter   BW_MUL  =   160
    parameter   BW_MUL  =   96
)(
    input   [31 : 0]            busA_in,
    input   [31 : 0]            busB_in,
    output  [BW_MUL - 1 : 0]    half_Result
);

    // wire    [15 : 0]    partial_sum [9 : 0];

    // assign  partial_sum[0] = busA_in[7 : 0] * busB_in[7 : 0];

    // assign  partial_sum[1] = busA_in[7 : 0] * busB_in[15 : 8];
    // assign  partial_sum[2] = busA_in[15 : 8] * busB_in[7 : 0];

    // assign  partial_sum[3] = busA_in[15 : 8] * busB_in[15 : 8];
    // assign  partial_sum[4] = busA_in[23 : 16] * busB_in[7 : 0];
    // assign  partial_sum[5] = busA_in[7 : 0] * busB_in[23 : 16];

    // assign  partial_sum[6] = busA_in[15 : 8] * busB_in[23 : 16];
    // assign  partial_sum[7] = busA_in[23 : 16] * busB_in[15 : 8];
    // assign  partial_sum[8] = busA_in[7 : 0] * busB_in[31 : 24];
    // assign  partial_sum[9] = busA_in[31 : 24] * busB_in[7 : 0];

    // assign  half_Result = {partial_sum[9], partial_sum[8], partial_sum[7], partial_sum[6], partial_sum[5],
    //                         partial_sum[4], partial_sum[3], partial_sum[2], partial_sum[1], partial_sum[0]};

    wire    [31 : 0]    partial_sum [2 : 0];

    assign  partial_sum[0] = busA_in[15 : 0] * busB_in[15 : 0];

    assign  partial_sum[1] = busA_in[15 : 0] * busB_in[31 : 16];
    assign  partial_sum[2] = busA_in[31 : 16] * busB_in[15 : 0];

    assign  half_Result = {partial_sum[2], partial_sum[1], partial_sum[0]};

endmodule


module  BRANCH_UNIT (
    input       [31 : 0]    busA,
    input       [31 : 0]    busB,
    input       [31 : 0]    pc,
    input       [31 : 0]    ExtImm32,
    input       [2 : 0]     BranchConf,
    output      [31 : 0]    BranchAddr,
    output  reg             Branch
);

    assign  BranchAddr = pc + 4 + (ExtImm32 << 2);

    always @(*) begin
        case (BranchConf)
            1:          Branch = (busA == busB)? 1 : 0;
            2:          Branch = (busA != busB)? 1 : 0;
            3:          Branch = (busA <= 0)? 1 : 0;
            4:          Branch = (busA > 0)? 1 : 0;
            5:          Branch = (busA < 0)? 1 : 0;
            default:    Branch = 0;
        endcase
    end

endmodule


module EX #(
    // parameter   BW_MUL  =   160
    parameter   BW_MUL  =   96
)(
    input   [31 : 0]    busA,
    input   [31 : 0]    busB,
    input   [31 : 0]    ExtImm32,
    input   [31 : 0]    pc,
    input   [3 : 0]     ALUConf,
    input   [2 : 0]     BranchConf,
    input   [4 : 0]     shamt,
    output  [31 : 0]    Result,
    output  [31 : 0]    BranchAddr,
    input               ALUSrc,
    output              Branch,
    output              USE_RT_EX,
    output              Mul,
    output [BW_MUL-1:0] half_Result
);

    wire    [31 : 0]    busA_in;
    wire    [31 : 0]    busB_in;
    assign  busA_in = busA;
    assign  busB_in = (ALUSrc == 1)? ExtImm32 : busB;

    assign  USE_RT_EX = (ALUSrc == 0 || BranchConf == 1 || BranchConf == 2)? 1 : 0;
    assign  Mul = (ALUConf == 4'd13)? 1 : 0;

    ALU u_ALU (
        .busA_in(busA_in),
        .busB_in(busB_in),
        .ALUConf(ALUConf),
        .shamt(shamt),
        .Result(Result)
    );

    MUL_UNIT_A #(
        .BW_MUL(BW_MUL)
    ) u_MUL_UNIT_A (
        .busA_in(busA_in),
        .busB_in(busB_in),
        .half_Result(half_Result)
    );

    BRANCH_UNIT u_BRANCH_UNIT (
        .busA(busA),
        .busB(busB),
        .pc(pc),
        .ExtImm32(ExtImm32),
        .BranchConf(BranchConf),
        .BranchAddr(BranchAddr),
        .Branch(Branch)
    );

endmodule