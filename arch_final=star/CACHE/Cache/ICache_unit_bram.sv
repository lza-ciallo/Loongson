module ICache_unit (
    input clk,
    input rst,
    //访问Cache并输出数据，返回是否命中
    input inst_read_ena,
    input  [31:0] pc,
    output  hit,//命中情况
    output [31:0] inst[3:0],//当hit=0时有效
    output [2:0]  inst_size,//当hit=1时有效
    output  replace_way,//被替换块的way编号,当hit=0时有效
    output  dirty,//被替换块的dirty值,当hit=0时有效,对ICache没有什么意义
    //接受写入信息对ICache进行更新
    input  ICache_Wena,
    input  update_way,
    input [31:0] update_pc,
    input [127:0] ICache_line
);
    // 元数据结构
    typedef struct{
        reg [19:0]  tag;  // 20位
        reg         age;   // 用于实现最近最少使用法
        reg         valid;   
        reg         dirty;
    } ICache_meta;

    // 元数据寄存器
    ICache_meta ICache_meta_way0[255:0];
    ICache_meta ICache_meta_way1[255:0];
    
    // 地址划分
    wire [7:0]  index = pc[11:4];    // 8位索引
    wire [19:0] tag = pc[31:12];     // 20位标签
    wire [3:0]  info = pc[3:0];      // 4位偏移

    wire [7:0]  update_index = update_pc[11:4];   // 更新索引
    wire [19:0] update_tag = update_pc[31:12];    // 更新标签
    
    // BRAM输出
    wire [127:0] inst_bram_way0;
    wire [127:0] inst_bram_way1;
    
    // 保存偏移量和命中信息
    reg [3:0]   saved_info;
    reg         hit_way0_reg;
    reg         hit_way1_reg;
    
    // 判断是否命中（组合逻辑）
    wire hit_way0 = ICache_meta_way0[index].valid && (ICache_meta_way0[index].tag == tag);
    wire hit_way1 = ICache_meta_way1[index].valid && (ICache_meta_way1[index].tag == tag);
    assign hit = hit_way0 || hit_way1;
    
    // 配置指令输出
    assign inst_size = (saved_info == 4'b0000) ? 4 :
                       (saved_info == 4'b0100) ? 3 :
                       (saved_info == 4'b1000) ? 2 : 1;
    
    // 指令选择逻辑
    wire [31:0] inst_way0[3:0];
    wire [31:0] inst_way1[3:0];
    
    // way0数据选择
    assign inst_way0[0] = (saved_info == 4'b0000) ? inst_bram_way0[31:0]   :
                          (saved_info == 4'b0100) ? inst_bram_way0[63:32]  :
                          (saved_info == 4'b1000) ? inst_bram_way0[95:64]  : inst_bram_way0[127:96];
    assign inst_way0[1] = (saved_info == 4'b0000) ? inst_bram_way0[63:32]  :
                          (saved_info == 4'b0100) ? inst_bram_way0[95:64]  :
                          (saved_info == 4'b1000) ? inst_bram_way0[127:96] : 32'b0;
    assign inst_way0[2] = (saved_info == 4'b0000) ? inst_bram_way0[95:64]  :
                          (saved_info == 4'b0100) ? inst_bram_way0[127:96] : 32'b0;
    assign inst_way0[3] = (saved_info == 4'b0000) ? inst_bram_way0[127:96] : 32'b0;
    
    // way1数据选择
    assign inst_way1[0] = (saved_info == 4'b0000) ? inst_bram_way1[31:0]   :
                          (saved_info == 4'b0100) ? inst_bram_way1[63:32]  :
                          (saved_info == 4'b1000) ? inst_bram_way1[95:64]  : inst_bram_way1[127:96];
    assign inst_way1[1] = (saved_info == 4'b0000) ? inst_bram_way1[63:32]  :
                          (saved_info == 4'b0100) ? inst_bram_way1[95:64]  :
                          (saved_info == 4'b1000) ? inst_bram_way1[127:96] : 32'b0;
    assign inst_way1[2] = (saved_info == 4'b0000) ? inst_bram_way1[95:64]  :
                          (saved_info == 4'b0100) ? inst_bram_way1[127:96] : 32'b0;
    assign inst_way1[3] = (saved_info == 4'b0000) ? inst_bram_way1[127:96] : 32'b0;
    
    // 最终指令输出
    genvar geni;
    generate
        for(geni = 0; geni < 4; geni = geni + 1) begin
            assign inst[geni] = hit_way0_reg ? inst_way0[geni] : 
                                hit_way1_reg ? inst_way1[geni] : 32'b0;
        end
    endgenerate
    
    // 替换逻辑策略
    wire old_way = (ICache_meta_way0[index].age >= ICache_meta_way1[index].age) ? 1'b0 : 1'b1;
    wire empty_way = ICache_meta_way0[index].valid ? 1'b1 : 1'b0;
    wire empty_or_not = ~ICache_meta_way0[index].valid || ~ICache_meta_way1[index].valid;
    assign replace_way = empty_or_not ? empty_way : old_way;
    
    // 配置dirty
    assign dirty = (replace_way) ? ICache_meta_way0[index].dirty : ICache_meta_way1[index].dirty;
    
    // BRAM 实例化 - 使用组合逻辑直接连接
    ICache_inst_block inst_ram_way0 (
        .clka(clk),
        .ena(1'b1),  // 始终使能
        .wea(ICache_Wena && (update_way == 1'b0)), // 写使能：更新时且选择way0
        .addra(ICache_Wena ? update_index : index), // 写时用更新地址，读时用当前地址
        .dina(ICache_line), // 写入数据
        .douta(inst_bram_way0) // 读出数据（有1周期延迟）
    );
    
    ICache_inst_block inst_ram_way1 (
        .clka(clk),
        .ena(1'b1),  // 始终使能
        .wea(ICache_Wena && (update_way == 1'b1)), // 写使能：更新时且选择way1
        .addra(ICache_Wena ? update_index : index), // 写时用更新地址，读时用当前地址
        .dina(ICache_line), // 写入数据
        .douta(inst_bram_way1) // 读出数据（有1周期延迟）
    );
    
    // 保存偏移量和命中信息（用于下个周期数据选择）
    always_ff @(posedge clk) begin
        if (inst_read_ena) begin
            hit_way0_reg <= hit_way0;
            hit_way1_reg <= hit_way1;
            saved_info <= info;  // 保存偏移量
        end
    end
    
    // 元数据更新
    always_ff @(posedge clk or negedge rst) begin
        integer i;
        if(!rst) begin
            // 初始化元数据
            for(i = 0; i < 256; i = i + 1) begin
                ICache_meta_way0[i] <= '{tag:0, age:0, valid:0, dirty:0};
                ICache_meta_way1[i] <= '{tag:0, age:0, valid:0, dirty:0};
            end
        end
        else begin
            // 读访问时的年龄更新
            if(inst_read_ena && hit) begin
                if(hit_way0) begin
                    ICache_meta_way0[index].age <= 1'b0;
                    ICache_meta_way1[index].age <= 1'b1;
                end
                else begin
                    ICache_meta_way0[index].age <= 1'b1;
                    ICache_meta_way1[index].age <= 1'b0;
                end
            end
            
            // Cache行更新
            if(ICache_Wena) begin
                if(update_way == 1'b0) begin
                    // 更新way0
                    ICache_meta_way0[update_index].tag <= update_tag;
                    ICache_meta_way0[update_index].age <= ~ICache_meta_way1[update_index].age;
                    ICache_meta_way0[update_index].valid <= 1'b1;
                    ICache_meta_way0[update_index].dirty <= 1'b0;
                end
                else begin
                    // 更新way1
                    ICache_meta_way1[update_index].tag <= update_tag;
                    ICache_meta_way1[update_index].age <= ~ICache_meta_way1[update_index].age;
                    ICache_meta_way1[update_index].valid <= 1'b1;
                    ICache_meta_way1[update_index].dirty <= 1'b0;
                end
            end
        end
    end
endmodule