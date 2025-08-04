//取指模块要取指令时把rena拉高，直到读到rdone为高时本周期输出数据有效
module ICache_top #(
    parameter WAYS = 2,
    parameter CACHELINE_WIDTH = 128,
    parameter CACHELINE_NUMS = 1024,
    parameter PC_WIDTH = 10,
    parameter TAG_WIDTH = 18
)(
    // 系统信号
    input           clk,
    input           rst,
    // 面向控制单元的信号
    output          stall_if_request,
    input           flush_ICache,
    // 面向取指模块的数据传输线
    output [31:0]   inst[3:0],
    output          find_inst[3:0],
    input  [31:0]   pc,
    input           Rena,
    output          Rdone,
    // 面向axi总线的相应信号
    output          req_valid,
    input           req_ready,
    output [31:0]   req_pc,
    input           res_valid,
    output          res_ready,
    input  [127:0]  res_Rdata
);

typedef enum { 
    fastresponse, 
    readoutput,      // 新增状态：处理BRAM读延迟
    waithandshaking, 
    waitresponse 
} ICache_state;

// 状态寄存器
ICache_state current_state, next_state;

// ICache_unit接口信号
wire hit;
wire replace_way;
wire dirty; // 虽然ICache只读，但保留接口

// 更新ICache的信号
reg ICache_Wena;
reg [31:0] update_pc_reg;
reg replace_way_reg;

// 未命中时锁存PC
reg [31:0] miss_pc;

// 新增寄存器：保存读请求信息
reg [31:0] saved_pc;
reg        saved_rena;
reg        saved_flush;

// 状态寄存器更新
always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        current_state <= fastresponse;
    end else begin
        current_state <= next_state;
    end
end

// 状态转移逻辑（增加readoutput状态）
always_comb begin
    next_state = current_state;
    case (current_state)
        fastresponse: begin
            // 读使能且命中时进入读输出状态
            if (Rena && hit) begin
                next_state = readoutput;
            end
            // 读使能且未命中时进入等待握手状态
            else if (Rena && !hit) begin
                next_state = waithandshaking;
            end
        end
        readoutput: begin  // 新增状态
            // 单周期状态，完成后继续响应
            // 读使能且命中时保持读输出状态
            if (Rena && hit) begin
                next_state = readoutput;
            end
            // 读使能且未命中时进入等待握手状态
            else if (Rena && !hit) begin
                next_state = waithandshaking;
            end
            else begin
                next_state = fastresponse; // 没有读请求时返回快速响应状态
            end
        end
        waithandshaking: begin
            // 握手成功进入等待响应状态
            if (req_ready) begin
                next_state = waitresponse;
            end
        end
        waitresponse: begin
            // 收到响应数据后回到快速响应状态
            if (res_valid) begin
                next_state = fastresponse;
            end
        end
    endcase
end

// 锁存未命中的PC和替换路信息
always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        miss_pc <= 32'b0;
        replace_way_reg <= 1'b0;
        saved_pc <= 32'b0;
        saved_rena <= 1'b0;
        saved_flush <= 1'b0;
    end else begin
        if ((current_state == fastresponse || current_state == readoutput) && Rena ) begin
            // 保存当前读请求信息
            saved_pc <= pc;
            saved_rena <= Rena;
            
            // 如果是未命中，锁存信息
            if (!hit) begin
                miss_pc <= pc;
                replace_way_reg <= replace_way;
            end
        end
        if (flush_ICache && stall_if_request) begin
            saved_flush <= 1'b1; //记录flush状态
        end
        else if(!stall_if_request) begin
            saved_flush <= 1'b0; // 清除flush状态
        end
    end
end

// 输出逻辑（调整Rdone和stall逻辑）
assign stall_if_request = (current_state != fastresponse && current_state != readoutput) || 
                         (current_state == fastresponse && Rena && !hit) || (current_state == readoutput && Rena && !hit);

assign req_valid = (current_state == waithandshaking);
assign req_pc = miss_pc & 32'hFFFF_FFF0; // 对齐到缓存行边界
assign res_ready = (current_state == waitresponse);

// Rdone在readoutput状态有效
assign Rdone = (current_state == readoutput);

// ICache更新控制
always_comb begin
    if (current_state == waitresponse && res_valid) begin
        ICache_Wena = 1'b1;
        update_pc_reg = miss_pc;
    end
    else begin
        ICache_Wena = 1'b0;
        update_pc_reg = 32'b0;
    end
end

wire [2:0] inst_size;
assign find_inst[0] = saved_flush ? 0 :~saved_rena ? 1 : (inst_size >= 1) ? 1 : 0;
assign find_inst[1] = saved_flush ? 0 :~saved_rena ? 1 : (inst_size >= 2) ? 1 : 0;
assign find_inst[2] = saved_flush ? 0 :~saved_rena ? 1 : (inst_size >= 3) ? 1 : 0;
assign find_inst[3] = saved_flush ? 0 :~saved_rena ? 1 : (inst_size >= 4) ? 1 : 0;
// 实例化ICache单元
ICache_unit icache_unit (
    .clk(clk),
    .rst(rst),
    .inst_read_ena(Rena && (current_state == fastresponse || current_state == readoutput)), // 使用保存的读使能
    .pc(pc),                    // 使用保存的PC
    .hit(hit),
    .inst(inst),
    .inst_size(inst_size),
    .replace_way(replace_way),
    .dirty(dirty),
    .ICache_Wena(ICache_Wena),
    .update_way(replace_way_reg),
    .update_pc(update_pc_reg),
    .ICache_line(res_Rdata)
);

endmodule