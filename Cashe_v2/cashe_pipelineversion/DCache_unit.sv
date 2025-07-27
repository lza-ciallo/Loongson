// 重构后的 DCache_unit 模块
// 使用BRAM实现，引入一级流水线处理读延迟
module DCache_unit (
    input clk,
    input rst,
    // 访问Cache的使能信号，只在一个周期有效
    input data_read_ena,
    input data_write_ena,
    input [31:0] addr,
    input [1:0]  data_size, // 00:字节, 10:半字, 11:字
    output hit,             // 命中情况，延迟一拍输出
    output [3:0] Rmask,     // 读掩码
    output [31:0] data_read,// 当hit=1时有效
    input  [3:0] Wmask,     // 写掩码
    input  [31:0] data_write,// 写数据
    output replace_way,     // 被替换块的way编号,当hit=0时有效
    output dirty,           // 被替换块的dirty值,当hit=0时有效
    // 接受从内存的写入信息对DCache进行更新
    input  DCache_Wena,
    input  update_way,
    input [31:0] update_addr,
    input [127:0] update_DCache_line,
    // 从DCache把数据读出用于写回到内存
    input wb_ena,
    input [31:0] wb_addr,
    input wb_way,
    output [127:0] wb_DCache_line
);
    // 地址分割 (组合逻辑)
    wire [7:0]  index      = addr[11:4];
    wire [19:0] tag        = addr[31:12];
    wire [7:0]  update_index = update_addr[11:4];
    wire [19:0] update_tag   = update_addr[31:12];
    wire [7:0]  wb_index     = wb_addr[11:4];

    // --- BRAM 存储体声明 ---
    // 综合器会将这些 reg 数组推断为BRAM
    // 1. Tag + Metadata BRAM: 256深度, 宽度为 20(tag) + 1(valid) + 1(dirty) + 1(age) = 23位
    localparam META_WIDTH = 23;
    reg [META_WIDTH-1:0] tag_meta_ram_way0[255:0];
    reg [META_WIDTH-1:0] tag_meta_ram_way1[255:0];

    // 2. Data BRAM: 256深度, 128位宽度
    reg [127:0] data_ram_way0[255:0];
    reg [127:0] data_ram_way1[255:0];

    // --- 流水线寄存器 (P1 stage) ---
    // 在访存请求来的那一拍锁存所需信息
    reg [7:0]  index_p1;
    reg [19:0] tag_p1;
    reg [3:0]  offset_p1;
    reg [1:0]  data_size_p1;
    reg [3:0]  Wmask_p1;
    reg [31:0] data_write_p1;
    reg        data_read_ena_p1;
    reg        data_write_ena_p1;

    // --- 周期1: 锁存输入, 发起BRAM读 ---
    always @(posedge clk) begin
        if (data_read_ena || data_write_ena) begin
            index_p1          <= index;
            tag_p1            <= tag;
            offset_p1         <= addr[3:0];
            data_size_p1      <= data_size;
            Wmask_p1          <= Wmask;
            data_write_p1     <= data_write;
            data_read_ena_p1  <= data_read_ena;
            data_write_ena_p1 <= data_write_ena;
        end else begin
            // 防止不必要的触发
            data_read_ena_p1  <= 1'b0;
            data_write_ena_p1 <= 1'b0;
        end
    end

    // BRAM 读操作 (行为级模型)
    // tag_meta_ram的地址由当前周期的index决定, 其输出在下一周期有效
    // 为了匹配流水线, 我们使用锁存后的index_p1来读取
    wire [META_WIDTH-1:0] tag_meta_out_way0 = tag_meta_ram_way0[index_p1];
    wire [META_WIDTH-1:0] tag_meta_out_way1 = tag_meta_ram_way1[index_p1];
    wire [127:0] data_out_way0 = data_ram_way0[index_p1];
    wire [127:0] data_out_way1 = data_ram_way1[index_p1];
    
    // --- 周期2: Tag比较, 命中判断, 数据选择 ---
    // 从Tag BRAM输出中解析元数据
    wire [19:0] tag_from_bram_way0 = tag_meta_out_way0[22:3];
    wire valid_from_bram_way0      = tag_meta_out_way0[2];
    wire dirty_from_bram_way0      = tag_meta_out_way0[1];
    wire age_from_bram_way0        = tag_meta_out_way0[0];

    wire [19:0] tag_from_bram_way1 = tag_meta_out_way1[22:3];
    wire valid_from_bram_way1      = tag_meta_out_way1[2];
    wire dirty_from_bram_way1      = tag_meta_out_way1[1];
    wire age_from_bram_way1        = tag_meta_out_way1[0];

    // 命中逻辑 (现在是同步的)
    wire hit_way0 = valid_from_bram_way0 && (tag_from_bram_way0 == tag_p1);
    wire hit_way1 = valid_from_bram_way1 && (tag_from_bram_way1 == tag_p1);
    assign hit = (data_read_ena_p1 || data_write_ena_p1) && (hit_way0 || hit_way1);

    // 读数据输出逻辑
    logic [31:0] data_word_way0, data_word_way1;
    always_comb begin
        case(offset_p1[3:2])
            2'b00: data_word_way0 = data_out_way0[31:0];
            2'b01: data_word_way0 = data_out_way0[63:32];
            2'b10: data_word_way0 = data_out_way0[95:64];
            2'b11: data_word_way0 = data_out_way0[127:96];
        endcase
        case(offset_p1[3:2])
            2'b00: data_word_way1 = data_out_way1[31:0];
            2'b01: data_word_way1 = data_out_way1[63:32];
            2'b10: data_word_way1 = data_out_way1[95:64];
            2'b11: data_word_way1 = data_out_way1[127:96];
        endcase
    end
    assign data_read = hit_way0 ? data_word_way0 : data_word_way1;

    // 读掩码 Rmask (基于流水线中的信息)
    assign Rmask = (data_size_p1 == 2'b11) ? 4'b1111 :
                   (data_size_p1 == 2'b10) ? 4'b0011 << {offset_p1[1], 1'b0} :
                   (4'b0001 << offset_p1[1:0]);

    // 替换逻辑 (基于BRAM输出的实时信息)
    wire old_way = (age_from_bram_way0 >= age_from_bram_way1) ? 1'b0 : 1'b1;
    wire empty_way0_exists = ~valid_from_bram_way0;
    wire empty_way1_exists = ~valid_from_bram_way1;
    // 优先替换无效行
    assign replace_way = empty_way0_exists ? 1'b0 : (empty_way1_exists ? 1'b1 : old_way);
    
    // 被替换行的dirty位
    assign dirty = (replace_way == 1'b0) ? dirty_from_bram_way0 : dirty_from_bram_way1;

    // 写回数据输出 (BRAM的读是同步的，但这里的地址是直接给的，可以认为是异步读或一拍延迟)
    // 为了简单，我们假设写回控制器会提前一拍设置地址
    assign wb_DCache_line = wb_way ? data_ram_way1[wb_index] : data_ram_way0[wb_index];
    
    // --- BRAM 写逻辑 ---
    always @(posedge clk) begin
        integer i;
        if (rst) begin
            for (i = 0; i < 256; i = i + 1) begin
                tag_meta_ram_way0[i] <= 0;
                tag_meta_ram_way1[i] <= 0;
                // data_ram的内容无需复位，节省资源
            end
        end else begin
            // --- 命中时的写操作 和 Age更新 ---
            if (data_write_ena_p1 && hit) begin // 写命中
                if (hit_way0) begin
                    logic [127:0] temp_data = data_out_way0; //读出旧数据
                    // 根据掩码修改数据 (Byte-wise update)
                    for (int j = 0; j < 4; j++) begin
                        if(Wmask_p1[j]) temp_data[offset_p1[3:2]*32 + j*8 +: 8] = data_write_p1[j*8 +: 8];
                    end
                    data_ram_way0[index_p1] <= temp_data;
                    // 更新dirty位和age位
                    tag_meta_ram_way0[index_p1] <= {tag_from_bram_way0, valid_from_bram_way0, 1'b1, 1'b0};
                    tag_meta_ram_way1[index_p1][0] <= 1'b1; // 更新另一路的age
                end else begin // hit_way1
                    logic [127:0] temp_data = data_out_way1;
                    for (int j = 0; j < 4; j++) begin
                        if(Wmask_p1[j]) temp_data[offset_p1[3:2]*32 + j*8 +: 8] = data_write_p1[j*8 +: 8];
                    end
                    data_ram_way1[index_p1] <= temp_data;
                    tag_meta_ram_way1[index_p1] <= {tag_from_bram_way1, valid_from_bram_way1, 1'b1, 1'b0};
                    tag_meta_ram_way0[index_p1][0] <= 1'b1;
                end
            end else if (data_read_ena_p1 && hit) begin // 读命中，仅更新Age
                 if (hit_way0) begin
                    tag_meta_ram_way0[index_p1][0] <= 1'b0;
                    tag_meta_ram_way1[index_p1][0] <= 1'b1;
                end else begin // hit_way1
                    tag_meta_ram_way0[index_p1][0] <= 1'b1;
                    tag_meta_ram_way1[index_p1][0] <= 1'b0;
                end
        end

            // --- Miss后的更新操作 (由DCache_top控制) ---
            if (DCache_Wena) begin
                if (update_way == 1'b0) begin
                    data_ram_way0[update_index] <= update_DCache_line;
                    // 更新Tag, Valid, Dirty, Age
                    // 新载入的行，age设为0(最新)，另一路age设为1(最旧)
                    tag_meta_ram_way0[update_index] <= {update_tag, 1'b1, 1'b0, 1'b0}; 
                    tag_meta_ram_way1[update_index][0] <= 1'b1; 
                end else begin
                    data_ram_way1[update_index] <= update_DCache_line;
                    tag_meta_ram_way1[update_index] <= {update_tag, 1'b1, 1'b0, 1'b0};
                    tag_meta_ram_way0[update_index][0] <= 1'b1;
                end
            end

            // --- 写回后清除Dirty位 ---
            if (wb_ena) begin
                if (wb_way == 1'b0) begin
                    tag_meta_ram_way0[wb_index][1] <= 1'b0; // 清除dirty位
                end else begin
                    tag_meta_ram_way1[wb_index][1] <= 1'b0;
                end
            end
        end
    end
endmodule