`include "../defs.svh"

module mul_wrapper #(
    parameter   MUL_TIME    =   1
)(
    input               clk,
    input               rst,
    input               flush_back,

    input   [31 : 0]    busA,
    input   [31 : 0]    busB,
    input   [ 3 : 0]    Conf,
    output  [31 : 0]    Result_mul,

    input   [ 5 : 0]    Pd,
    input               ready,
    input               RegWr,
    input   [ 5 : 0]    tag_rob,

    output  [ 5 : 0]    Pd_mul,
    output              ready_mul,
    output              RegWr_mul,
    output  [ 5 : 0]    tag_rob_mul,
    output              is_mul
);

    wire    [ 3 : 0]    Conf_mul;
    assign  is_mul  =   (Conf_mul == `MUL_CONF || Conf_mul == `MULH_CONF || Conf_mul == `MULHU_CONF)? 1 : 0;

    typedef struct packed {
        reg [ 5 : 0]    Pd;
        reg             ready;
        reg             RegWr;
        reg [ 5 : 0]    tag_rob;
        reg [ 3 : 0]    Conf;
        reg             Sign;
    } mul_entry;

    mul_entry   pipe    [MUL_TIME-1 : 0];

    // 需要进行符号翻转的标志
    assign  Sign = (busA[31] != busB[31])? 1 : 0;

    always @(posedge clk) begin
        if (~rst | flush_back) begin
            for (integer i = 0; i <MUL_TIME; i = i + 1) begin
                pipe[i] <=  '0;
            end
        end
        else begin
            pipe[0]     <=  {Pd, ready, RegWr, tag_rob, Conf, Sign};
            for (integer i = 1; i < MUL_TIME; i = i + 1) begin
                pipe[i] <=  pipe[i-1];
            end
        end
    end

    assign  {Pd_mul, ready_mul, RegWr_mul, tag_rob_mul, Conf_mul, Sign_mul} = pipe[MUL_TIME-1];

    wire    [31 : 0]    busA_abs;
    wire    [31 : 0]    busB_abs;
    wire    [63 : 0]    Result_abs;
    wire    [63 : 0]    Result_signed;

    assign  busA_abs = ((Conf == `MULH_CONF || Conf == `MUL_CONF) && busA[31] == 1)? ~busA + 1'b1 : busA;
    assign  busB_abs = ((Conf == `MULH_CONF || Conf == `MUL_CONF) && busB[31] == 1)? ~busB + 1'b1 : busB;
    assign  Result_signed = Sign_mul? ~Result_abs + 1'b1 : Result_abs;

    mul_unsigned u_mul (
        .CLK    (clk),                  // input wire CLK
        .A      (busA_abs),             // input wire [31 : 0] A
        .B      (busB_abs),             // input wire [31 : 0] B
        .SCLR   (~rst | flush_back),    // input wire SCLR
        .P      (Result_abs)            // output wire [63 : 0] P
    );

    assign  Result_mul  =   (Conf_mul == `MUL_CONF)? Result_signed[31 : 0] :
                            (Conf_mul == `MULH_CONF)? Result_signed[63 : 32] :
                            (Conf_mul == `MULHU_CONF)? Result_abs[63 : 32] : '0;
    
endmodule