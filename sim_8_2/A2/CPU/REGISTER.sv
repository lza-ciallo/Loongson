module REGISTER #(
    parameter   BW  =   256
)(
    input                       clk,
    input                       rst,
    input                       flush,
    input                       stall,

    input       [BW - 1 : 0]    data_in,
    output  reg [BW - 1 : 0]    data_out
);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            data_out        <=  '0;
        end
        else begin
            if (flush) begin
                data_out    <=  '0;
            end
            else if (stall) begin
                data_out    <=  data_out;
            end
            else begin
                data_out    <=  data_in;
            end
        end
    end

endmodule