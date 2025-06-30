module ARF (
    input               clk,
    input               rst,
    input               RegWr,
    input       [2 : 0] Rw,
    input       [3 : 0] tag_PRF,

    output  reg [3 : 0] ARF_tag [7 : 0]
);

    integer i;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                ARF_tag[i] <= i;
            end
        end
        else begin
            if (RegWr && Rw != 0) begin
                ARF_tag[Rw] <= tag_PRF;
            end
        end
    end

endmodule