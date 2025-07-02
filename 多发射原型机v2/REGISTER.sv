module REGISTER #(
    parameter   BW  =   256
)(
    input                       clk,
    input                       rst,
    input                       stall,
    input                       flush,
    input       [BW - 1 : 0]    data_in,
    output  reg [BW - 1 : 0]    data_out
);

endmodule