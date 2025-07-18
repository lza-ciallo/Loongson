module Pipeline_wrapper (
    input               clk,
    input               rst,
    // output  reg [7 : 0] leds,
    // output  reg [3 : 0] enable,
    output      [7 : 0] leds,
    output      [3 : 0] enable,
    output      [3 : 0] indicator
    // output              locked
);

    assign  indicator = enable;

    // integer count;
    // wire    [7 : 0]     leds_real;
    wire    [3 : 0]     enable_real;

    // wire    clk_real;

    // PLL u_PLL (
    //     .clk_out1(clk_real),    // output clk_out1
    //     .reset(rst),            // input reset
    //     .locked(locked),        // output locked
    //     .clk_in1(clk)           // input clk_in1
    // );

    Pipeline5 u_Pipeline5 (
        .clk(clk),
        .rst(rst),
        .leds(leds),
        .enable(enable_real)
    );

    assign  enable = ~enable_real;

    // always @(posedge clk_real or negedge rst) begin
    //     if (!rst) begin
    //         count <= 0;
    //         leds <= 0;
    //         enable <= 0;
    //     end
    //     else begin
    //         if (count == 499_999) begin
    //             count <= 0;
    //             leds <= leds_real;
    //             enable <= ~enable_real;
    //         end
    //         else begin
    //             count <= count + 1;
    //         end
    //     end
    // end

endmodule
