module DCache_unit (
    input clk,
    input rst,
    // 访问Cache并输出数据，返回是否命中
    input data_read_ena,
    input data_write_ena,
    input  [31:0] addr,
    input [1:0]  data_size, // 00:字节, 10:半字, 11:字
    output  hit, // 命中情况
    output [3:0] Rmask,   // 读掩码
    output [31:0] data_read, // 当hit=1时有效
    input  [3:0] Wmask,   // 写掩码
    input  [31:0] data_write, // 当hit=1时才能写入cache，同时把对应行的dirty拉高
    output  replace_way, // 被替换块的way编号,当hit=0时有效
    output  dirty, // 被替换块的dirty值,当hit=0时有效
    // 接受从内存的写入信息对DCache进行更新
    input  DCache_Wena,
    input  update_way,
    input [31:0] update_addr,
    input [127:0] update_DCache_line,
    // 从DCache把数据读出用于写回到内存
    input wb_ena,
    input [31:0] wb_addr,
    input wb_way,         // 写回哪一路
    output [127:0] wb_DCache_line
);
    typedef struct {
        reg [17:0]  tag;
        reg [127:0] data; // 数据存储
        reg         age; // 用于实现最近最少使用法
        reg         valid;   
        reg         dirty;
    } DCacheline;
    DCacheline DCache_way0[1023:0];
    DCacheline DCache_way1[1023:0];
    
    // 分割地址信号
    wire [9:0]  index = addr[31:22];
    wire [17:0] tag = addr[21:4];
    wire [3:0]  offset = addr[3:0];
    
    wire [9:0]  update_index = update_addr[31:22];
    wire [17:0] update_tag = update_addr[21:4];
    
    wire [9:0]  wb_index = wb_addr[31:22];
    wire [17:0] wb_tag = wb_addr[21:4];
    
    // 判断是否命中
    wire hit_way0 = DCache_way0[index].valid && (DCache_way0[index].tag == tag);
    wire hit_way1 = DCache_way1[index].valid && (DCache_way1[index].tag == tag);
    assign hit = hit_way0 || hit_way1;
    
    logic [31:0] data_way0, data_way1;
    always_comb begin
        // Way0
        case(offset[3:2])
            2'b00: data_way0 = DCache_way0[index].data[31:0];
            2'b01: data_way0 = DCache_way0[index].data[63:32];
            2'b10: data_way0 = DCache_way0[index].data[95:64];
            2'b11: data_way0 = DCache_way0[index].data[127:96];
        endcase
        // Way1
        case(offset[3:2])
            2'b00: data_way1 = DCache_way1[index].data[31:0];
            2'b01: data_way1 = DCache_way1[index].data[63:32];
            2'b10: data_way1 = DCache_way1[index].data[95:64];
            2'b11: data_way1 = DCache_way1[index].data[127:96];
        endcase
    end
    assign data_read = hit_way0 ? data_way0 : data_way1;
    // 生成读掩码Rmask(小端序)
    assign Rmask = (data_size == 2'b11) ? 4'b1111 : // 字访问
                   (data_size == 2'b10) ? 4'b0011 << {offset[1], 1'b0} : // 半字访问
                   (4'b0001 << offset[1:0]); // 字节访问
    // 替换逻辑策略
    wire old_way = (DCache_way0[index].age >= DCache_way1[index].age) ? 1'b0 : 1'b1;
    wire empty_way = DCache_way0[index].valid ? 1'b0 : 1'b1;
    wire empty_or_not = ~DCache_way0[index].valid || ~DCache_way1[index].valid;
    assign replace_way = empty_or_not ? empty_way : old_way;
    // 配置dirty
    assign dirty = replace_way ? DCache_way1[index].dirty : DCache_way0[index].dirty;
    // 写回数据输出（根据wb_way选择）
    assign wb_DCache_line = wb_way ? DCache_way1[wb_index].data : DCache_way0[wb_index].data;
    // 数据写入逻辑
    always @(posedge clk or negedge rst) begin
        integer i;
        if (!rst) begin
            for (i = 0; i < 1024; i = i + 1) begin
                DCache_way0[i] <= '{default:0};
                DCache_way1[i] <= '{default:0};
            end
        end
        else begin
            // 正常读写操作
            if ((data_read_ena || data_write_ena) && hit) begin
                // 更新LRU年龄
                if (hit_way0) begin
                    DCache_way0[index].age <= 1'b0;
                    DCache_way1[index].age <= 1'b1;
                end
                else begin
                    DCache_way0[index].age <= 1'b1;
                    DCache_way1[index].age <= 1'b0;
                end
                // 写入操作（根据Wmask按字节写入）
                //堆序在这里可能是一个问题，后面debug的时候要注意

                if (data_write_ena && hit) begin
                    // 根据偏移量确定写入位置
                    if (hit_way0) begin
                        case(offset[3:2])
                            2'b00: begin
                                if (Wmask[0]) DCache_way0[index].data[7:0]   <= data_write[7:0];
                                if (Wmask[1]) DCache_way0[index].data[15:8]  <= data_write[15:8];
                                if (Wmask[2]) DCache_way0[index].data[23:16] <= data_write[23:16];
                                if (Wmask[3]) DCache_way0[index].data[31:24] <= data_write[31:24];
                            end
                            2'b01: begin
                                if (Wmask[0]) DCache_way0[index].data[39:32]  <= data_write[7:0];
                                if (Wmask[1]) DCache_way0[index].data[47:40]  <= data_write[15:8];
                                if (Wmask[2]) DCache_way0[index].data[55:48] <= data_write[23:16];
                                if (Wmask[3]) DCache_way0[index].data[63:56] <= data_write[31:24];
                            end
                            2'b10: begin
                                if (Wmask[0]) DCache_way0[index].data[71:64]  <= data_write[7:0];
                                if (Wmask[1]) DCache_way0[index].data[79:72]  <= data_write[15:8];
                                if (Wmask[2]) DCache_way0[index].data[87:80] <= data_write[23:16];
                                if (Wmask[3]) DCache_way0[index].data[95:88] <= data_write[31:24];
                            end
                            2'b11: begin
                                if (Wmask[0]) DCache_way0[index].data[103:96]  <= data_write[7:0];
                                if (Wmask[1]) DCache_way0[index].data[111:104] <= data_write[15:8];
                                if (Wmask[2]) DCache_way0[index].data[119:112] <= data_write[23:16];
                                if (Wmask[3]) DCache_way0[index].data[127:120] <= data_write[31:24];
                            end
                        endcase
                        DCache_way0[index].dirty <= 1'b1; // 设置脏位
                    end
                    else begin // hit_way1
                        case(offset[3:2])
                            2'b00: begin
                                if (Wmask[0]) DCache_way1[index].data[7:0]   <= data_write[7:0];
                                if (Wmask[1]) DCache_way1[index].data[15:8]  <= data_write[15:8];
                                if (Wmask[2]) DCache_way1[index].data[23:16] <= data_write[23:16];
                                if (Wmask[3]) DCache_way1[index].data[31:24] <= data_write[31:24];
                            end
                            2'b01: begin
                                if (Wmask[0]) DCache_way1[index].data[39:32]  <= data_write[7:0];
                                if (Wmask[1]) DCache_way1[index].data[47:40]  <= data_write[15:8];
                                if (Wmask[2]) DCache_way1[index].data[55:48] <= data_write[23:16];
                                if (Wmask[3]) DCache_way1[index].data[63:56] <= data_write[31:24];
                            end
                            2'b10: begin
                                if (Wmask[0]) DCache_way1[index].data[71:64]  <= data_write[7:0];
                                if (Wmask[1]) DCache_way1[index].data[79:72]  <= data_write[15:8];
                                if (Wmask[2]) DCache_way1[index].data[87:80] <= data_write[23:16];
                                if (Wmask[3]) DCache_way1[index].data[95:88] <= data_write[31:24];
                            end
                            2'b11: begin
                                if (Wmask[0]) DCache_way1[index].data[103:96]  <= data_write[7:0];
                                if (Wmask[1]) DCache_way1[index].data[111:104] <= data_write[15:8];
                                if (Wmask[2]) DCache_way1[index].data[119:112] <= data_write[23:16];
                                if (Wmask[3]) DCache_way1[index].data[127:120] <= data_write[31:24];
                            end
                        endcase
                        DCache_way1[index].dirty <= 1'b1; // 设置脏位
                    end
                end
            end
            //从内存加载新数据更新Dcache
            if (DCache_Wena) begin
                if (update_way == 1'b0) begin
                    DCache_way0[update_index].tag   <= update_tag;
                    DCache_way0[update_index].data  <= update_DCache_line;
                    DCache_way0[update_index].valid <= 1'b1;
                    DCache_way0[update_index].dirty <= 1'b0; // 新加载的数据是干净的
                    DCache_way0[update_index].age   <= ~DCache_way1[update_index].age;
                end
                else begin
                    DCache_way1[update_index].tag   <= update_tag;
                    DCache_way1[update_index].data  <= update_DCache_line;
                    DCache_way1[update_index].valid <= 1'b1;
                    DCache_way1[update_index].dirty <= 1'b0; // 新加载的数据是干净的
                    DCache_way1[update_index].age   <= ~DCache_way0[update_index].age;
                end
            end
            // 写回操作后顺便把脏位清楚了防止触发误判
            if (wb_ena) begin
                if (wb_way == 1'b0) begin
                    DCache_way0[wb_index].dirty <= 1'b0;
                end
                else begin
                    DCache_way1[wb_index].dirty <= 1'b0;
                end
            end
        end
    end
endmodule