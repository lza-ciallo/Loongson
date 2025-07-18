module main_memory #(
    parameter ADDR_WIDTH = 12, 
    parameter DATA_WIDTH = 256
)(
    input                       clk,
    input                       req,
    input                       we,
    input  [ADDR_WIDTH-1:0]     addr,
    input  [DATA_WIDTH-1:0]     wdata,
    output reg [DATA_WIDTH-1:0] rdata,
    output reg                  ready
);

    // BRAM IP核的读出数据
    wire [DATA_WIDTH-1:0] bram_dout;
    
    reg read_req_d1; // "d1" for 1-cycle delay

    // 在每个时钟沿更新这个延迟寄存器
    always @(posedge clk) begin
        read_req_d1 <= req & ~we;
    end

    // ready 信号由这个延迟寄存器驱动
    // 这样 ready 信号会在读请求发起后的下一个周期变高
    always @(posedge clk) begin
        ready <= read_req_d1;
    end

    // 读数据寄存，与新的ready信号同步
    // 当 read_req_d1 为高时，意味着上个周期是读请求，
    // 此刻 bram_dout 上的数据正好是有效的。
    always @(posedge clk) begin
        if (read_req_d1) begin
            rdata <= bram_dout;
        end
    end

    bram u_bram (
      .clka(clk),
      .ena(req),
      .wea({we}), // 注意：wea通常是一个位宽大于1的向量，{we}是好的写法
      .addra(addr),
      .dina(wdata),
      .douta(bram_dout)
    );

endmodule