// 重构后的 DCache_top 模块
// 状态机调整以适应BRAM的一拍延迟
module DCache_top #(
    // 参数保持不变
    parameter WAYS = 2,
    parameter CACHELINE_WIDTH = 128,
    parameter CACHELINE_NUMS = 1024,
    parameter PC_WIDTH = 10,
    parameter TAG_WIDTH = 18
)(
    // 接口保持不变
    input clk,
    input rst,
    output stall_mem_request,
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
    // --- 状态机定义 (修改) ---
    typedef enum { 
        IDLE,                   // 新增：空闲状态，等待请求
        WAIT_HIT,               // 新增：等待DCache_unit的命中结果
        waithandshaking_clean, 
        waithandshaking_dirty,
        waitresponse 
    } DCache_state;
    DCache_state current_state, next_state;

    // DCache_unit接口信号
    wire hit;
    wire replace_way;
    wire dirty;
    wire [127:0] wb_DCache_line;
    
    // --- 锁存未命中请求信息的逻辑保持不变 ---
    reg [31:0] miss_addr;
    reg [31:0] miss_data;
    reg [1:0]  miss_size;
    reg [3:0]  miss_mask;
    reg        miss_we;
    reg        miss_way;

    // --- 状态机时序逻辑 ---
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // --- 状态机组合逻辑 (核心修改) ---
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                // 收到CPU的读或写请求
                if (Rena || Wena) begin
                    next_state = WAIT_HIT;
                end
            end
            WAIT_HIT: begin
                // 在此状态末尾, hit信号有效
                if (hit) begin
                    // 命中! 操作完成, 返回IDLE
                    next_state = IDLE;
                end else begin
                    // 未命中, 根据dirty位决定下一步
                    if (dirty) begin
                        next_state = waithandshaking_dirty;
                    end else begin
                        next_state = waithandshaking_clean;
                    end
                end
            end
            waithandshaking_dirty: begin
                if (req_ready) begin
                    next_state = waithandshaking_clean;
                end
            end
            waithandshaking_clean: begin
                if (req_ready) begin
                    next_state = waitresponse;
                end
            end
            waitresponse: begin
                if (res_valid) begin
                    next_state = IDLE;
                end
            end
        endcase
    end
    
    // --- 锁存未命中信息 (修改触发条件) ---
    always_ff @(posedge clk) begin
        if(rst) begin
            // ... 复位逻辑
        end
        // 在从WAIT_HIT状态转移且发现未命中时锁存
        else if (current_state == WAIT_HIT && !hit) begin
            miss_addr <= (Rena ? Raddr : Waddr);
            miss_data <= Wdata;
            miss_size <= (Rena ? Rsize : Wsize);
            miss_mask <= Wmask;
            miss_we   <= Wena;
            miss_way  <= replace_way;
        end
    end
    
    // --- 控制信号和输出逻辑 ---
    
    // stall信号：只要不在IDLE且没有命中，就阻塞后续请求
    assign stall_mem_request = (current_state != IDLE);
    
    // 读写完成信号
    assign Rdone = (current_state == WAIT_HIT) && hit && Rena;
    assign Wdone = (current_state == WAIT_HIT) && hit && Wena;

    // 传递给DCache_unit的使能信号，只在IDLE状态且有请求时有效一拍
    wire dcache_read_ena  = (current_state == IDLE) && Rena;
    wire dcache_write_ena = (current_state == IDLE) && Wena;

    // DCache更新控制 (基本不变，仅状态判断调整)
    wire DCache_Wena = (current_state == waitresponse && res_valid);
    wire [31:0] update_addr_reg = miss_addr;
    wire update_way_reg = miss_way;
    
    // 写回控制 (基本不变)
    wire wb_ena = (current_state == waithandshaking_dirty); // 写回发生在状态转换时
    wire [31:0] wb_addr_reg = {miss_addr[31:12], miss_addr[11:4], 4'b0}; // 写回地址对齐
    wire wb_way_reg = miss_way;

    // 面向AXI总线的信号 (逻辑基本不变，仅状态判断调整)
    assign req_valid = (current_state == waithandshaking_dirty) || (current_state == waithandshaking_clean);
    assign write_en  = (current_state == waithandshaking_dirty);
    assign req_addr  = write_en ? {wb_addr_reg[31:4], 4'b0} : {miss_addr[31:4], 4'b0};
    assign req_Wdata = wb_DCache_line;
    assign res_ready = (current_state == waitresponse);
    
    // --- 实例化DCache单元 ---
    DCache_unit dcache_unit_inst (
        .clk(clk),
        .rst(rst),
        // 使能信号只在IDLE态发出
        .data_read_ena(dcache_read_ena),
        .data_write_ena(dcache_write_ena),
        // 地址和数据在IDLE态发出
        .addr(Wena ? Waddr : Raddr),
        .data_size(Wena ? Wsize : Rsize),
        .hit(hit), // 从dcache_unit接收延迟一拍的hit信号
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