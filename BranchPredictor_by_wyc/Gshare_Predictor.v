module Gshare_predictor #(
    parameter K         = 13, 
    parameter GHR_WIDTH = K   
) (
    input                       clk,
    input                       rst,
    
    input       [31:0]          pc_in,          
    
    input                       update_en,      
    input       [31:0]          update_pc,     
    input       [GHR_WIDTH-1:0] update_ghr_val, // 更新时分支对应的GHR值
    input                       actual_taken,   

    output wire                 prediction     
);

    localparam PHT_SIZE = 1 << K;

    reg [1:0] pht[0:PHT_SIZE-1];

    // 全局历史寄存器 
    reg [GHR_WIDTH-1:0] ghr;

    wire [K-1:0] pht_index_predict;
    wire [K-1:0] pht_index_update;
    reg  [1:0]   pht_entry_current;
    reg  [1:0]   pht_entry_next;

    // 哈希：PC低位与GHR异或生成PHT索引
    assign pht_index_predict = pc_in[K+1:2] ^ ghr;

    // 更新阶段的PHT索引
    assign pht_index_update  = update_pc[K+1:2] ^ update_ghr_val;

    assign prediction = pht[pht_index_predict][1];


    always @(posedge clk or posedge rst) begin
        if (rst) begin

            for (integer i = 0; i < PHT_SIZE; i = i + 1) begin
                pht[i] <= 2'b01;
            end
            ghr <= {GHR_WIDTH{1'b0}};
        end else if (update_en) begin
            pht[pht_index_update] <= pht_entry_next;
            ghr <= {ghr[GHR_WIDTH-2:0], actual_taken};
        end
    end

    always @(*) begin
        pht_entry_current = pht[pht_index_update]; 
        pht_entry_next = pht_entry_current; 
     // 计算下一个状态的组合逻辑
        case (pht_entry_current)
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