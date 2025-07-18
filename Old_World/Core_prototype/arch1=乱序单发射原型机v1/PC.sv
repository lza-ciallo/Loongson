module PC (
    input               clk,
    input               rst,
    input               stall,
    output  reg [7 : 0] pc,
    output  reg         valid_pc
);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            pc <= -1;
            valid_pc <= 0;
        end
        else if (stall) begin
            pc <= pc;
            valid_pc <= 1;
        end
        else begin
            pc <= pc + 1;
            valid_pc <= 1;
        end
    end
    
endmodule