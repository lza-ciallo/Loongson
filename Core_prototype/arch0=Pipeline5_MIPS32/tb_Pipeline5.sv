`timescale 1ns / 1ps
`define CLK_PERIOD 10

module tb_Pipeline5;

    reg             clk;
    reg             rst;
    wire    [7 : 0] leds;
    wire    [3 : 0] enable;
    wire    [3 : 0] indicator;
    wire            locked;

    // Pipeline5 u_Pipeline5 (
    //     .clk(clk),
    //     .rst(rst),
    //     .leds(leds),
    //     .enable(enable)
    // );

    Pipeline_wrapper u_Pipeline_wrapper (
        .clk(clk),
        .rst(rst),
        .leds(leds),
        .enable(enable),
        .indicator(indicator),
        .locked(locked)
    );

    initial begin
        clk = 0;
        forever begin
            #(`CLK_PERIOD / 2) clk = ~clk;
        end
    end

    initial begin
        rst = 1;
        @(negedge clk) rst = 0;
        @(negedge clk) rst = 1;
    end

endmodule