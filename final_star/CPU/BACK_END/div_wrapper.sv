`include "../defs.svh"

module div_wrapper #(
    parameter   DIV_TIME    =   16
)(
    input               clk,
    input               rst,
    input               flush_back,

    input   [31 : 0]    busA,
    input   [31 : 0]    busB,
    input   [ 3 : 0]    Conf,
    output  [31 : 0]    Result_divmod,

    input   [ 5 : 0]    Pd,
    input               ready,
    input               RegWr,
    input   [ 5 : 0]    tag_rob,

    output  [ 5 : 0]    Pd_divmod,
    output              ready_divmod,
    output              RegWr_divmod,
    output  [ 5 : 0]    tag_rob_divmod,
    output              is_divmod
);

    wire    [ 3 : 0]    Conf_divmod;
    assign  is_divmod   =   (Conf_divmod == `DIV_CONF || Conf_divmod == `DIVU_CONF || Conf_divmod == `MOD_CONF || Conf_divmod == `MODU_CONF)? 1 : 0;

    typedef struct packed {
        reg [ 5 : 0]    Pd;
        reg             ready;
        reg             RegWr;
        reg [ 5 : 0]    tag_rob;
        reg [ 3 : 0]    Conf;
        reg             Sign_div;
        reg             Sign_mod;
    } div_entry;

    div_entry   pipe    [DIV_TIME-1 : 0];

    // 需要进行符号翻转的标志
    assign  Sign_div = (busA[31] != busB[31])? 1 : 0;
    assign  Sign_mod = busA[31];

    always @(posedge clk) begin
        if (~rst | flush_back) begin
            for (integer i = 0; i <DIV_TIME; i = i + 1) begin
                pipe[i] <=  '0;
            end
        end
        else begin
            pipe[0]     <=  {Pd, ready, RegWr, tag_rob, Conf, Sign_div, Sign_mod};
            for (integer i = 1; i < DIV_TIME; i = i + 1) begin
                pipe[i] <=  pipe[i-1];
            end
        end
    end

    assign  {Pd_divmod, ready_divmod, RegWr_divmod, tag_rob_divmod, Conf_divmod, Sign_div_r, Sign_mod_r} = pipe[DIV_TIME-1];

    wire    [31 : 0]    divisor_abs;
    wire    [31 : 0]    dividend_abs;
    wire    [31 : 0]    quotient_abs;
    wire    [31 : 0]    remainder_abs;

    assign  dividend_abs = ((Conf == `DIV_CONF || Conf == `MOD_CONF) && busA[31] == 1)? ~busA + 1 : busA;
    assign  divisor_abs = ((Conf == `DIV_CONF || Conf == `MOD_CONF) && busB[31] == 1)? ~busB + 1 : busB;

    div_unsigned u_div (
        .aclk                   (clk),                          // input wire aclk
        .aresetn                (rst & ~flush_back),            // input wire aresetn
        .s_axis_divisor_tvalid  (1'b1),                         // input wire s_axis_divisor_tvalid
        .s_axis_divisor_tdata   (divisor_abs),                  // input wire [31 : 0] s_axis_divisor_tdata
        .s_axis_dividend_tvalid (1'b1),                         // input wire s_axis_dividend_tvalid
        .s_axis_dividend_tdata  (dividend_abs),                 // input wire [31 : 0] s_axis_dividend_tdata
        // .m_axis_dout_tvalid(m_axis_dout_tvalid),             // output wire m_axis_dout_tvalid
        .m_axis_dout_tdata      ({quotient_abs, remainder_abs}) // output wire [63 : 0] m_axis_dout_tdata
    );

    assign  Result_divmod = (Conf_divmod == `DIV_CONF)? (Sign_div_r? ~quotient_abs + 1 : quotient_abs) :
                            (Conf_divmod == `DIVU_CONF)? quotient_abs :
                            (Conf_divmod == `MOD_CONF)? (Sign_mod_r? ~remainder_abs + 1 : remainder_abs) :
                            (Conf_divmod == `MODU_CONF)? remainder_abs : '0;
                        
endmodule