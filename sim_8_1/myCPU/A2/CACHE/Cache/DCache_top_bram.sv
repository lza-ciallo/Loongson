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
    input  flush_DCache,//!
    output stall_mem_request,//!
    // 面向访存模块的数据传输线
    input [31:0] addr,
    input [3:0]  Conf_dmem,//配置信息，只需要识别B/H/W即可,结合addr的最后两位判断
    input [31:0] Wdata,
    input        Wena,
    output       Wdone,
    output [31:0] Rdata,
    input        Rena,
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
    //处理mask/size/conf/addr的转化问题
    reg [3:0]  Wmask;
    // reg [3:0]  Rmask;
    always_comb begin
        if(Conf_dmem == 0 || Conf_dmem == 3 || Conf_dmem == 6)begin//B
            case (addr[1:0])
                2'b00: Wmask = 4'b0001;
                2'b01: Wmask = 4'b0010;
                2'b10: Wmask = 4'b0100;
                2'b11: Wmask = 4'b1000;
            endcase
        end
        else if(Conf_dmem == 1 || Conf_dmem == 4 || Conf_dmem == 7)begin//H
            case (addr[1:0])
                2'b00: Wmask = 4'b0011;
                2'b01: Wmask = 4'b0011;
                2'b10: Wmask = 4'b1100;
                2'b11: Wmask = 4'b1100;
            endcase
        end
        else if(Conf_dmem == 2 || Conf_dmem == 5)begin//W
            Wmask = 4'b1111;
        end
        else begin
            Wmask = 4'b0000; // 默认值，防止综合错误
        end
    end
    wire [31:0] Waddr;
    wire [31:0] Raddr;
    assign      Waddr = addr;
    assign      Raddr = addr;
    // 增加reqprocess状态处理BRAM读延迟和写操作
    typedef enum { 
        fastresponse, 
        reqprocess,        // 新增状态：处理读写请求
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
    
    // 锁存请求信息
    reg [31:0] saved_addr;
    reg [31:0] saved_data;
    reg [3:0]  saved_mask;
    reg        saved_we;
    reg        saved_way;
    
    // 状态寄存器更新
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= fastresponse;
        end else begin
            current_state <= next_state;
        end
    end
    
    // 状态转移逻辑（增加reqprocess状态）
    always_comb begin
        next_state = current_state;
        case (current_state)
            fastresponse: begin
                // 读写请求
                if (Rena || Wena) begin
                    if (hit) begin
                        next_state = reqprocess;  // 命中时进入请求处理状态
                    end else begin
                        // 未命中根据dirty位决定状态转移
                        if (dirty) begin
                            next_state = waithandshaking_dirty;
                        end else begin
                            next_state = waithandshaking_clean;
                        end
                    end
                end
            end
            reqprocess: begin  // 新增状态
                // 处理完成后返回快速响应
                next_state = fastresponse;
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
                    next_state = fastresponse;
                end
            end
        endcase
    end
    
    // 锁存请求信息
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            saved_addr <= 32'b0;
            saved_data <= 32'b0;
            saved_mask <= 4'b0;
            saved_we <= 1'b0;
            saved_way <= 1'b0;
        end else begin
            // 在fastresponse状态锁存请求信息
            if (current_state == fastresponse && (Rena || Wena)) begin
                saved_addr <= Wena ? Waddr : Raddr;
                saved_data <= Wdata;
                saved_mask <= Wmask;
                saved_we <= Wena;
                saved_way <= replace_way;
            end
        end
    end
    
    // 输出逻辑
    assign stall_mem_request = (current_state != fastresponse && current_state != reqprocess) || 
                              (current_state == fastresponse && (Rena || Wena));
    
    assign req_valid = (current_state == waithandshaking_dirty) || 
                      (current_state == waithandshaking_clean);
    
    assign write_en = (current_state == waithandshaking_dirty);
    
    assign req_addr = (current_state == waithandshaking_dirty) ? 
                     {saved_addr[31:4], 4'b0} :  // 写回地址对齐
                     {saved_addr[31:4], 4'b0};    // 读请求地址对齐
    
    assign req_Wdata = wb_DCache_line;
    
    assign res_ready = (current_state == waitresponse);
    
    // 读写完成信号（在reqprocess状态完成）
    assign Wdone = (current_state == reqprocess) && saved_we;
    assign Rdone = (current_state == reqprocess) && !saved_we;
    
    // DCache更新控制
    reg DCache_Wena;
    reg [31:0] update_addr_reg;
    reg update_way_reg;
    
    always_comb begin
        DCache_Wena = 1'b0;
        update_addr_reg = 32'b0;
        update_way_reg = 1'b0;
        
        if (current_state == waitresponse && res_valid) begin
            DCache_Wena = 1'b1;
            update_addr_reg = saved_addr;
            update_way_reg = saved_way;
        end
    end
    
    // 写回控制
    reg wb_ena;
    reg [31:0] wb_addr_reg;
    reg wb_way_reg;
    
    always_comb begin
        wb_ena = 1'b0;
        wb_addr_reg = 32'b0;
        wb_way_reg = 1'b0;
        
        if (current_state == waithandshaking_dirty && req_ready) begin
            wb_ena = 1'b1;
            wb_addr_reg = saved_addr;
            wb_way_reg = saved_way;
        end
    end
    
    
    // 实例化DCache单元
    DCache_unit dcache_unit (
        .clk(clk),
        .rst(rst),
        .data_read_ena(Rena && (current_state == fastresponse)),
        .data_write_ena(Wena && (current_state == fastresponse)),
        .addr(Wena ? Waddr : Raddr),
        .hit(hit),
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
        .wb_DCache_line(wb_DCache_line),
        // 新增信号
        .process_ena(current_state == reqprocess),
        .saved_we(saved_we),
        .saved_addr(saved_addr),
        .saved_data(saved_data),
        .saved_mask(saved_mask)
    );
    
endmodule