module REGISTER #(
    parameter   BW      =   512
)(
    input   clk,
    input   rst,
    input   stall,
    input   flush,
    input       [BW - 1 : 0]    data_in,
    output  reg [BW - 1 : 0]    data_out
);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            data_out <= '0;
        end
        else if (flush) begin
            data_out <= '0;
        end
        else if (stall) begin
            data_out <= data_out;
        end
        else begin
            data_out <= data_in;
        end
    end

endmodule