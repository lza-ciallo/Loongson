module AGU (
    input                   clk,
    input                   rst,
    input                   flush_back,

    input       [31 : 0]    dataj,
    input       [31 : 0]    imm,
    output  reg [31 : 0]    Addr_r,

    input                   ready,
    input       [ 5 : 0]    tag_rob,

    output  reg             ready_r,
    output  reg [ 5 : 0]    tag_rob_r
);

    wire        [31 : 0]    Addr;

    assign  Addr    =   dataj + imm;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            {Addr_r, ready_r, tag_rob_r}        <=  '0;
        end
        else begin
            if (flush_back) begin
                {Addr_r, ready_r, tag_rob_r}    <=  '0;
            end
            else begin
                {Addr_r, ready_r, tag_rob_r}    <=  {Addr, ready, tag_rob};
            end
        end
    end

endmodule