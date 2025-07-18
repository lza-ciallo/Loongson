
module branch_predictor #(
    parameter K = 13 //根据一些经验，k=13收益比比较高，反正可以调整
) (
    input                          clk,
    input                          rst,
    
    input      [31:0]              pc_in,         // 分支指令的PC地址
    
    // 来自执行/写回阶段的更新信号
    input                          update_en,     // 使能PHT更新
    input      [31:0]              update_pc,     // 需要更新的分支指令的PC
    input                          actual_taken,  // 1=Taken, 0=Not-Taken

    // 输出到取指阶段
    output wire                    prediction     // 预测结果 (1=Taken, 0=Not-Taken)
);

    localparam PHT_SIZE = 1 << K;

    // 2位饱和计数器
    // 初始化为 '弱不跳转' (01)
    reg [1:0] pht[0:PHT_SIZE-1];

    wire [K-1:0] pht_index_predict;
    wire [K-1:0] pht_index_update;
    reg  [1:0]   pht_entry_current;
    reg  [1:0]   pht_entry_next;

    // PHT的索引
    assign pht_index_predict = pc_in[K+1:2];
    assign pht_index_update  = update_pc[K+1:2];

    // 预测结果是PHT条目的MSB
    assign prediction = pht[pht_index_predict][1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (integer i = 0; i < PHT_SIZE; i = i + 1) begin
                pht[i] <= 2'b01;
            end
        end else if (update_en) begin
            pht[pht_index_update] <= pht_entry_next;
        end
    end

    // 计算下一个状态的组合逻辑
    always @(*) begin
        pht_entry_current = pht[pht_index_update];
        pht_entry_next = pht_entry_current; 
        case (pht_entry_current)
            // 强不跳转 
            2'b00: begin
                if (actual_taken) begin
                    pht_entry_next = 2'b01; // -> 弱不跳转
                end
            end
            // 弱不跳转 
            2'b01: begin
                if (actual_taken) begin
                    pht_entry_next = 2'b10; // -> 弱跳转
                end else begin
                    pht_entry_next = 2'b00; // -> 强不跳转
                end
            end
            // 弱跳转 
            2'b10: begin
                if (actual_taken) begin
                    pht_entry_next = 2'b11; // -> 强跳转
                end else begin
                    pht_entry_next = 2'b01; // -> 弱不跳转
                end
            end
            // 强跳转
            2'b11: begin
                if (!actual_taken) begin
                    pht_entry_next = 2'b10; // -> 弱跳转
                end
            end
            default: pht_entry_next = 2'b01; 
        endcase
    end

endmodule