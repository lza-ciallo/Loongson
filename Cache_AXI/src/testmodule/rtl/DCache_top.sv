module DCache_top #(
    parameter WAYS = 2,
    parameter CACHELINE_WIDTH = 128,
    parameter CACHELINE_NUMS = 1024,
    parameter PC_WIDTH = 10,
    parameter TAG_WIDTH = 18
)(
    // 系统信号
    input clk,
    input rst,
    // 面向控制单元的信号
    output stall_mem_request,
    // 面向访存模块的数据传输线
    input [31:0] Wdata,
    input [31:0] Waddr,
    input        Wena,
    input [1:0]  Wsize,
    input [3:0]  Wmask,
    output       Wdone,
    output [31:0] Rdata,
    input  [31:0] Raddr,
    input        Rena,
    input  [1:0]  Rsize,
    output [3:0] Rmask,
    output       Rdone,
    // 面向axi总线的相应信号
    output        req_valid,
    input         req_ready,
    output [31:0] req_addr,
    output        write_en,
    output [127:0] req_Wdata,
    input         res_valid,
    output        res_ready,
    input  [127:0] res_Rdata,
    input  [1:0]   axi_Wdone
);
    typedef enum { 
        fastresponse, 
        waithandshaking_clean,
        waithandshaking_dirty,
        waitresponse 
    } DCache_state;
    // 状态寄存器
    DCache_state current_state, next_state;
    // DCache_unit接口信号
    wire hit;
    wire replace_way;
    wire dirty;
    wire [127:0] wb_DCache_line;
    // 锁存未命中的请求信息
    reg [31:0] miss_addr;
    reg [31:0] miss_data;
    reg [1:0]  miss_size;
    reg [3:0]  miss_mask;
    reg        miss_we;
    reg        miss_way;
    // 更新DCache的信号
    reg DCache_Wena;
    reg [31:0] update_addr_reg;
    reg update_way_reg;
    // 写回控制信号
    reg wb_ena;
    reg [31:0] wb_addr_reg;
    reg wb_way_reg;
    // 状态寄存器更新
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= fastresponse;
        end else begin
            current_state <= next_state;
        end
    end
    // 状态转移逻辑
    always_comb begin
        next_state = current_state;
        case (current_state)
            fastresponse: begin
                // 读写请求且未命中
                if ((Rena || Wena) && !hit) begin
                    // 根据dirty位决定状态转移
                    if (dirty) begin
                        next_state = waithandshaking_dirty;
                    end else begin
                        next_state = waithandshaking_clean;
                    end
                end
            end
            waithandshaking_dirty: begin
                // 写回请求握手成功
                if (req_ready) begin
                    next_state = waithandshaking_clean;
                end
            end
            waithandshaking_clean: begin
                // 读请求握手成功
                if (req_ready) begin
                    next_state = waitresponse;
                end
            end
            waitresponse: begin
                // 收到响应数据
                if (res_valid) begin
                    next_state = fastresponse;
                end
            end
        endcase
    end
    
    // 锁存未命中的请求信息和替换路信息
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            miss_addr <= 32'b0;
            miss_data <= 32'b0;
            miss_size <= 2'b0;
            miss_mask <= 4'b0;
            miss_we <= 1'b0;
            miss_way <= 1'b0;
        end else if (current_state == fastresponse && (Rena || Wena) && !hit) begin
            miss_addr <= Wena ? Waddr : Raddr;
            miss_data <= Wdata;
            miss_size <= Wena ? Wsize : Rsize;
            miss_mask <= Wmask;
            miss_we <= Wena;
            miss_way <= replace_way;
        end
    end
    
    // 输出逻辑
    assign stall_mem_request = (current_state != fastresponse);
    
    assign req_valid = (current_state == waithandshaking_dirty) || 
                      (current_state == waithandshaking_clean);
    
    assign write_en = (current_state == waithandshaking_dirty);
    
    assign req_addr = (current_state == waithandshaking_dirty) ? 
                     {wb_addr_reg[31:4], 4'b0} :  // 写回地址对齐
                     {miss_addr[31:4], 4'b0};      // 读请求地址对齐
    
    assign req_Wdata = wb_DCache_line;
    
    assign res_ready = (current_state == waitresponse);
    
    // 读写完成信号
    assign Wdone = (current_state == fastresponse) && hit && Wena;
    assign Rdone = (current_state == fastresponse) && hit && Rena;
    
    // DCache更新控制
    always_comb begin
        DCache_Wena = 1'b0;
        update_addr_reg = 32'b0;
        update_way_reg = 1'b0;
        
        if (current_state == waitresponse && res_valid) begin
            DCache_Wena = 1'b1;
            update_addr_reg = miss_addr;
            update_way_reg = miss_way;
        end
    end
    
    // 写回控制
    always_comb begin
        wb_ena = 1'b0;
        wb_addr_reg = 32'b0;
        wb_way_reg = 1'b0;
        
        if (current_state == waithandshaking_dirty && req_ready) begin
            wb_ena = 1'b1;
            wb_addr_reg = miss_addr;
            wb_way_reg = miss_way;
        end
    end
    
    // 实例化DCache单元
    DCache_unit dcache_unit (
        .clk(clk),
        .rst(rst),
        .data_read_ena(Rena && (current_state == fastresponse)),
        .data_write_ena(Wena && (current_state == fastresponse)),
        .addr(Wena ? Waddr : Raddr),
        .data_size(Wena ? Wsize : Rsize),
        .hit(hit),
        .Rmask(Rmask),
        .data_read(Rdata),
        .Wmask(Wmask),
        .data_write(Wdata),
        .replace_way(replace_way),
        .dirty(dirty),
        .DCache_Wena(DCache_Wena),
        .update_way(update_way_reg),
        .update_addr(update_addr_reg),
        .update_DCache_line(res_Rdata),
        .wb_ena(wb_ena),
        .wb_addr(wb_addr_reg),
        .wb_way(wb_way_reg),
        .wb_DCache_line(wb_DCache_line)
    );
    
endmodule