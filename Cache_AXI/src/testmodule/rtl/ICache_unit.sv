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
    typedef struct{
        reg [19:0]  tag;  // 改为20位
        reg [127:0] inst;
        reg         age;//用于实现最近最少使用法
        reg         valid;   
        reg         dirty;
        //count用于记录最近的访问情况
    }ICacheline;
    ICacheline ICache_way0[255:0]; // 改为256行
    ICacheline ICache_way1[255:0]; // 改为256行
    
    // 地址划分修改（索引改为8位，标签改为20位）
    wire [7:0]  index = pc[11:4];    // 8位索引
    wire [19:0] tag = pc[31:12];     // 20位标签
    wire [3:0]  info = pc[3:0];      // 4位偏移不变

    wire [7:0]  update_index = update_pc[11:4];   // 更新索引
    wire [19:0] update_tag = update_pc[31:12];    // 更新标签
    
    //判断是否命中
    wire hit_way0 = ICache_way0[index].valid && (ICache_way0[index].tag == tag);
    wire hit_way1 = ICache_way1[index].valid && (ICache_way1[index].tag == tag);
    assign hit = hit_way0 || hit_way1;
    //配置指令输出
    assign inst_size = (info == 4'b0000) ? 4 :
                       (info == 4'b0100) ? 3 :
                       (info == 4'b1000) ? 2 : 1;
    wire [31:0] inst_way0[3:0];
    wire [31:0] inst_way1[3:0];
    //way0
    assign inst_way0[0] = (info == 4'b0000) ? ICache_way0[index].inst[31: 0] :
                   (info == 4'b0100) ? ICache_way0[index].inst[63: 32]  :
                   (info == 4'b1000) ? ICache_way0[index].inst[95: 64]  : ICache_way0[index].inst[127: 96];
    assign inst_way0[1] = (info == 4'b0000) ? ICache_way0[index].inst[63: 32]  :
                   (info == 4'b0100) ? ICache_way0[index].inst[95: 64] :
                   (info == 4'b1000) ? ICache_way0[index].inst[127: 96]  : 32'b0;
    assign inst_way0[2] = (info == 4'b0000) ? ICache_way0[index].inst[95: 64] :
                   (info == 4'b0100) ? ICache_way0[index].inst[127: 96]  :
                   (info == 4'b1000) ? 32'b0  : 32'b0;
    assign inst_way0[3] = (info == 4'b0000) ? ICache_way0[index].inst[127: 96] :
                   (info == 4'b0100) ? 32'b0 :
                   (info == 4'b1000) ? 32'b0  : 32'b0;
        //way1
    assign inst_way1[0] = (info == 4'b0000) ? ICache_way1[index].inst[31: 0] :
                   (info == 4'b0100) ? ICache_way1[index].inst[63: 32]  :
                   (info == 4'b1000) ? ICache_way1[index].inst[95: 64]  : ICache_way1[index].inst[127: 96];
    assign inst_way1[1] = (info == 4'b0000) ? ICache_way1[index].inst[63: 32]  :
                   (info == 4'b0100) ? ICache_way1[index].inst[95: 64] :
                   (info == 4'b1000) ? ICache_way1[index].inst[127: 96]  : 32'b0;
    assign inst_way1[2] = (info == 4'b0000) ? ICache_way1[index].inst[95: 64] :
                   (info == 4'b0100) ? ICache_way1[index].inst[127: 96]  :
                   (info == 4'b1000) ? 32'b0  : 32'b0;
    assign inst_way1[3] = (info == 4'b0000) ? ICache_way1[index].inst[127: 96] :
                   (info == 4'b0100) ? 32'b0 :
                   (info == 4'b1000) ? 32'b0  : 32'b0;
    genvar geni;
    generate
        for(geni = 0; geni < 4;geni = geni + 1)begin
            assign inst[geni] = hit_way0 ? inst_way0[geni] : inst_way1[geni];
        end
    endgenerate
    //替换逻辑策略
    wire old_way = (ICache_way0[index].age >= ICache_way1[index].age) ? 1'b0 : 1'b1;
    wire empty_way = ICache_way0[index].valid ? 1'b0 : 1'b1;
    wire empty_or_not = ~ICache_way0[index].valid || ~ICache_way1[index].valid;
    assign replace_way = empty_or_not ? empty_way : old_way;
    //配置dirty
    assign dirty = (replace_way) ? ICache_way0[index].dirty : ICache_way1[index].dirty;
    //配置ICacheline行内部的一些更新逻辑
    always @(posedge clk or negedge rst) begin
        integer i;
        if(!rst) begin
            for(i = 0;i < 256;i = i + 1) begin // 循环改为256次
                ICache_way0[i] <= '{default:0};
                ICache_way1[i] <= '{default:0};
            end
        end
        else begin
            if(inst_read_ena && hit) begin
                if(hit_way0) begin
                    ICache_way0[index].age <= 1'b0;
                    ICache_way1[index].age <= 1'b1;
                end
                else begin
                    ICache_way0[index].age <= 1'b1;
                    ICache_way1[index].age <= 1'b0;
                end
            end
            if(ICache_Wena) begin
                if(update_way == 1'b0) begin
                    ICache_way0[update_index].tag <= update_tag;
                    ICache_way0[update_index].age <= ~ ICache_way1[update_index].age;
                    ICache_way0[update_index].inst <= ICache_line;
                    ICache_way0[update_index].valid <= 1'b1;
                    ICache_way0[update_index].dirty <= 1'b0;
                end
                else begin
                    ICache_way1[update_index].tag <= update_tag;
                    ICache_way1[update_index].age <= ~ ICache_way1[update_index].age;
                    ICache_way1[update_index].inst <= ICache_line;
                    ICache_way1[update_index].valid <= 1'b1;
                    ICache_way1[update_index].dirty <= 1'b0;
                end
            end
        end
    end
endmodule