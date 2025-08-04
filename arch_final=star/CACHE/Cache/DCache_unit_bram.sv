module DCache_unit (
    input clk,
    input rst,
    // 访问Cache并输出数据，返回是否命中
    input data_read_ena,
    input data_write_ena,
    input  [31:0] addr,
    output  hit, // 命中情况
    output [31:0] data_read, // 当hit=1时有效
    input  [3:0] Wmask,   // 写掩码
    input  [31:0] data_write, // 当hit=1时才能写入cache，同时把对应行的dirty拉高
    output  replace_way, // 被替换块的way编号,当hit=0时有效
    output [31:0] replace_addr, // 被替换块的实际地址,当hit=0时有效
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
    output [127:0] wb_DCache_line,
    // 新增信号
    input process_ena,     // 处理请求使能
    input saved_we,        // 保存的写使能
    input [31:0] saved_addr, // 保存的地址
    input [31:0] saved_data, // 保存的数据
    input [3:0]  saved_mask,  // 保存的掩码
    input [1:0]  saved_size
);
    // 元数据结构
    typedef struct {
        reg [19:0]  tag;  // 20位
        reg         age;   // 用于实现最近最少使用法
        reg         valid;   
        reg         dirty;
    } DCache_meta;
    
    DCache_meta DCache_meta_way0[255:0]; // 256行
    DCache_meta DCache_meta_way1[255:0]; // 256行
    
    // 分割地址信号
    wire [7:0]  index = addr[11:4];   // 8位索引
    wire [19:0] tag = addr[31:12];    // 20位标签
    wire [3:0]  offset = addr[3:0];   // 4位偏移
    
    wire [7:0]  update_index = update_addr[11:4];   // 更新索引
    wire [19:0] update_tag = update_addr[31:12];    // 更新标签
    
    wire [7:0]  wb_index = wb_addr[11:4];           // 写回索引
    wire [19:0] wb_tag = wb_addr[31:12];            // 写回标签

    // 判断是否命中
    wire hit_way0 = DCache_meta_way0[index].valid && (DCache_meta_way0[index].tag == tag);
    wire hit_way1 = DCache_meta_way1[index].valid && (DCache_meta_way1[index].tag == tag);
    assign hit = hit_way0 || hit_way1;
    
    // BRAM输出
    wire [127:0] bram_data_way0;
    wire [127:0] bram_data_way1;
    
    // 保存偏移量和命中信息
    reg [3:0]   saved_offset;
    reg         hit_way0_reg;
    reg         hit_way1_reg;
    
    // 替换逻辑策略
    wire old_way = (DCache_meta_way0[index].age >= DCache_meta_way1[index].age) ? 1'b0 : 1'b1;
    wire empty_way = DCache_meta_way0[index].valid ? 1'b1 : 1'b0;
    wire empty_or_not = ~DCache_meta_way0[index].valid || ~DCache_meta_way1[index].valid;   //!
    assign replace_way = empty_or_not ? empty_way : old_way;
    
    assign replace_addr = {replace_way ? DCache_meta_way1[index].tag : DCache_meta_way0[index].tag, index, 4'b0000};
    // 配置dirty
    assign dirty = replace_way ? DCache_meta_way1[index].dirty : DCache_meta_way0[index].dirty;
    
    // 写回数据输出（根据wb_way选择）
    assign wb_DCache_line = wb_way ? bram_data_way1 : bram_data_way0;
    
    // 数据读取逻辑
    reg [31:0] read_data;
    always_comb begin
        // 根据偏移量选择数据
        case(saved_offset[3:2])
            2'b00: read_data = hit_way0_reg ? bram_data_way0[31:0] : bram_data_way1[31:0];
            2'b01: read_data = hit_way0_reg ? bram_data_way0[63:32] : bram_data_way1[63:32];
            2'b10: read_data = hit_way0_reg ? bram_data_way0[95:64] : bram_data_way1[95:64];
            2'b11: read_data = hit_way0_reg ? bram_data_way0[127:96] : bram_data_way1[127:96];
        endcase
    end
    assign data_read = read_data;
    
    // 写操作数据修改
    reg [127:0] modified_data;
    always_comb begin
        if (hit_way0_reg) begin
            modified_data = bram_data_way0;
            case(saved_offset[3:2])
                2'b00: begin
                    case(saved_offset[1:0])
                        2'b00: begin
                            case(saved_size) 
                                2'b00: modified_data[7:0]    = saved_data[7:0];
                                2'b01: modified_data[15:0]   = saved_data[15:0];
                                2'b10: modified_data[31:0]   = saved_data[31:0];
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                        2'b01: begin
                            case(saved_size) 
                                2'b00: modified_data[15:8]    = saved_data[7:0];
                                2'b01: modified_data[23:8]   = saved_data[15:0];
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end    
                        2'b10: begin
                            case(saved_size) 
                                2'b00: modified_data[23:16]    = saved_data[7:0];
                                2'b01: modified_data[31:16]   = saved_data[15:0];
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                        2'b11: begin
                            case(saved_size) 
                                2'b00: modified_data[31:24]    = saved_data[7:0];
                                2'b01: modified_data         = bram_data_way0;
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end                    
                    endcase
                end
                2'b01: begin
                    case(saved_offset[1:0])
                        2'b00: begin
                            case(saved_size) 
                                2'b00: modified_data[39:32]  = saved_data[7:0];
                                2'b01: modified_data[47:32]  = saved_data[15:0];
                                2'b10: modified_data[63:32]  = saved_data[31:0];
                                2'b11: modified_data         = bram_data_way0;  // 无法确定偏移，保持原样
                            endcase
                        end
                        2'b01: begin
                            case(saved_size) 
                                2'b00: modified_data[47:40]  = saved_data[7:0];
                                2'b01: modified_data[55:40]  = saved_data[15:0];
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end    
                        2'b10: begin
                            case(saved_size) 
                                2'b00: modified_data[55:48]  = saved_data[7:0];
                                2'b01: modified_data[63:48]  = saved_data[15:0];
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                        2'b11: begin
                            case(saved_size) 
                                2'b00: modified_data[63:56]  = saved_data[7:0];
                                2'b01: modified_data         = bram_data_way0;
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                    endcase
                end
                2'b10: begin
                    case(saved_offset[1:0])
                        2'b00: begin
                            case(saved_size) 
                                2'b00: modified_data[71:64]  = saved_data[7:0];
                                2'b01: modified_data[79:64]  = saved_data[15:0];
                                2'b10: modified_data[95:64]  = saved_data[31:0];
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                        2'b01: begin
                            case(saved_size) 
                                2'b00: modified_data[79:72]  = saved_data[7:0];
                                2'b01: modified_data[87:72]  = saved_data[15:0];
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end    
                        2'b10: begin
                            case(saved_size) 
                                2'b00: modified_data[87:80]  = saved_data[7:0];
                                2'b01: modified_data[95:80]  = saved_data[15:0];
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                        2'b11: begin
                            case(saved_size) 
                                2'b00: modified_data[95:88]  = saved_data[7:0];
                                2'b01: modified_data         = bram_data_way0;
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                    endcase
                end
                2'b11: begin
                    case(saved_offset[1:0])
                        2'b00: begin
                            case(saved_size) 
                                2'b00: modified_data[103:96] = saved_data[7:0];
                                2'b01: modified_data[111:96] = saved_data[15:0];
                                2'b10: modified_data[127:96] = saved_data[31:0];
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                        2'b01: begin
                            case(saved_size) 
                                2'b00: modified_data[111:104] = saved_data[7:0];
                                2'b01: modified_data[119:104] = saved_data[15:0];
                                2'b10: modified_data          = bram_data_way0;
                                2'b11: modified_data          = bram_data_way0;
                            endcase
                        end    
                        2'b10: begin
                            case(saved_size) 
                                2'b00: modified_data[119:112] = saved_data[7:0];
                                2'b01: modified_data[127:112] = saved_data[15:0];
                                2'b10: modified_data          = bram_data_way0;
                                2'b11: modified_data          = bram_data_way0;
                            endcase
                        end
                        2'b11: begin
                            case(saved_size) 
                                2'b00: modified_data[127:120] = saved_data[7:0];
                                2'b01: modified_data          = bram_data_way0;
                                2'b10: modified_data          = bram_data_way0;
                                2'b11: modified_data          = bram_data_way0;
                            endcase
                        end                    
                    endcase
                end
            endcase
        end else begin
            modified_data = bram_data_way1;
            case(saved_offset[3:2])
                2'b00: begin
                    case(saved_offset[1:0])
                        2'b00: begin
                            case(saved_size) 
                                2'b00: modified_data[7:0]    = saved_data[7:0];
                                2'b01: modified_data[15:0]   = saved_data[15:0];
                                2'b10: modified_data[31:0]   = saved_data[31:0];
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                        2'b01: begin
                            case(saved_size) 
                                2'b00: modified_data[15:8]    = saved_data[7:0];
                                2'b01: modified_data[23:8]   = saved_data[15:0];
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end    
                        2'b10: begin
                            case(saved_size) 
                                2'b00: modified_data[23:16]    = saved_data[7:0];
                                2'b01: modified_data[31:16]   = saved_data[15:0];
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                        2'b11: begin
                            case(saved_size) 
                                2'b00: modified_data[31:24]    = saved_data[7:0];
                                2'b01: modified_data         = bram_data_way0;
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end                    
                    endcase
                end
                2'b01: begin
                    case(saved_offset[1:0])
                        2'b00: begin
                            case(saved_size) 
                                2'b00: modified_data[39:32]  = saved_data[7:0];
                                2'b01: modified_data[47:32]  = saved_data[15:0];
                                2'b10: modified_data[63:32]  = saved_data[31:0];
                                2'b11: modified_data         = bram_data_way0;  // 无法确定偏移，保持原样
                            endcase
                        end
                        2'b01: begin
                            case(saved_size) 
                                2'b00: modified_data[47:40]  = saved_data[7:0];
                                2'b01: modified_data[55:40]  = saved_data[15:0];
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end    
                        2'b10: begin
                            case(saved_size) 
                                2'b00: modified_data[55:48]  = saved_data[7:0];
                                2'b01: modified_data[63:48]  = saved_data[15:0];
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                        2'b11: begin
                            case(saved_size) 
                                2'b00: modified_data[63:56]  = saved_data[7:0];
                                2'b01: modified_data         = bram_data_way0;
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                    endcase
                end
                2'b10: begin
                    case(saved_offset[1:0])
                        2'b00: begin
                            case(saved_size) 
                                2'b00: modified_data[71:64]  = saved_data[7:0];
                                2'b01: modified_data[79:64]  = saved_data[15:0];
                                2'b10: modified_data[95:64]  = saved_data[31:0];
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                        2'b01: begin
                            case(saved_size) 
                                2'b00: modified_data[79:72]  = saved_data[7:0];
                                2'b01: modified_data[87:72]  = saved_data[15:0];
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end    
                        2'b10: begin
                            case(saved_size) 
                                2'b00: modified_data[87:80]  = saved_data[7:0];
                                2'b01: modified_data[95:80]  = saved_data[15:0];
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                        2'b11: begin
                            case(saved_size) 
                                2'b00: modified_data[95:88]  = saved_data[7:0];
                                2'b01: modified_data         = bram_data_way0;
                                2'b10: modified_data         = bram_data_way0;
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                    endcase
                end
                2'b11: begin
                    case(saved_offset[1:0])
                        2'b00: begin
                            case(saved_size) 
                                2'b00: modified_data[103:96] = saved_data[7:0];
                                2'b01: modified_data[111:96] = saved_data[15:0];
                                2'b10: modified_data[127:96] = saved_data[31:0];
                                2'b11: modified_data         = bram_data_way0;
                            endcase
                        end
                        2'b01: begin
                            case(saved_size) 
                                2'b00: modified_data[111:104] = saved_data[7:0];
                                2'b01: modified_data[119:104] = saved_data[15:0];
                                2'b10: modified_data          = bram_data_way0;
                                2'b11: modified_data          = bram_data_way0;
                            endcase
                        end    
                        2'b10: begin
                            case(saved_size) 
                                2'b00: modified_data[119:112] = saved_data[7:0];
                                2'b01: modified_data[127:112] = saved_data[15:0];
                                2'b10: modified_data          = bram_data_way0;
                                2'b11: modified_data          = bram_data_way0;
                            endcase
                        end
                        2'b11: begin
                            case(saved_size) 
                                2'b00: modified_data[127:120] = saved_data[7:0];
                                2'b01: modified_data          = bram_data_way0;
                                2'b10: modified_data          = bram_data_way0;
                                2'b11: modified_data          = bram_data_way0;
                            endcase
                        end                    
                    endcase
                end
            endcase
        end
    end
    
    // BRAM 实例化
    DCache_data_block data_ram_way0 (
        .clka(clk),
        .ena(1'b1),  // 始终使能
        .wea((process_ena && saved_we && hit_way0_reg) ||  // 写操作
             (DCache_Wena && (update_way == 1'b0))), 
        .addra(process_ena ? saved_addr[11:4] : 
               DCache_Wena ? update_index : 
               wb_ena ? wb_index : index),
        .dina(process_ena ? modified_data : 
              DCache_Wena ? update_DCache_line : 
              wb_DCache_line),
        .douta(bram_data_way0)
    );
    
    DCache_data_block data_ram_way1 (
        .clka(clk),
        .ena(1'b1),  // 始终使能
        .wea((process_ena && saved_we && hit_way1_reg) ||  // 写操作
             (DCache_Wena && (update_way == 1'b1))), 
        .addra(process_ena ? saved_addr[11:4] : 
               DCache_Wena ? update_index : 
               wb_ena ? wb_index : index),
        .dina(process_ena ? modified_data : 
              DCache_Wena ? update_DCache_line : 
              wb_DCache_line),
        .douta(bram_data_way1)
    );
    
    // 保存偏移量和命中信息
    always_ff @(posedge clk) begin
        if (data_read_ena || data_write_ena) begin
            hit_way0_reg <= hit_way0;
            hit_way1_reg <= hit_way1;
            saved_offset <= offset;  // 保存偏移量
        end
    end
    
    // 元数据更新
    always_ff @(posedge clk or negedge rst) begin
        integer i;
        if (!rst) begin
            // 初始化元数据
            for (i = 0; i < 256; i = i + 1) begin
                DCache_meta_way0[i] <= '{tag:0, age:0, valid:0, dirty:0};
                DCache_meta_way1[i] <= '{tag:0, age:0, valid:0, dirty:0};
            end
        end
        else begin
            // 读访问时的年龄更新
            if ((data_read_ena || data_write_ena) && hit) begin
                if (hit_way0) begin
                    DCache_meta_way0[index].age <= 1'b0;
                    DCache_meta_way1[index].age <= 1'b1;
                end
                else begin
                    DCache_meta_way0[index].age <= 1'b1;
                    DCache_meta_way1[index].age <= 1'b0;
                end
            end
            
            // 写操作设置脏位
            if (process_ena && saved_we) begin
                if (hit_way0_reg) begin
                    DCache_meta_way0[saved_addr[11:4]].dirty <= 1'b1;
                end else if (hit_way1_reg) begin
                    DCache_meta_way1[saved_addr[11:4]].dirty <= 1'b1;
                end
            end
            
            // 从内存加载新数据更新Dcache
            if (DCache_Wena) begin
                if (update_way == 1'b0) begin
                    DCache_meta_way0[update_index].tag   <= update_tag;
                    DCache_meta_way0[update_index].valid <= 1'b1;
                    DCache_meta_way0[update_index].dirty <= 1'b0; // 新加载的数据是干净的
                    DCache_meta_way0[update_index].age   <= ~DCache_meta_way1[update_index].age;
                end
                else begin
                    DCache_meta_way1[update_index].tag   <= update_tag;
                    DCache_meta_way1[update_index].valid <= 1'b1;
                    DCache_meta_way1[update_index].dirty <= 1'b0; // 新加载的数据是干净的
                    DCache_meta_way1[update_index].age   <= ~DCache_meta_way0[update_index].age;
                end
            end
            
            // 写回操作后清除脏位
            if (wb_ena) begin
                if (wb_way == 1'b0) begin
                    DCache_meta_way0[wb_index].dirty <= 1'b0;
                end
                else begin
                    DCache_meta_way1[wb_index].dirty <= 1'b0;
                end
            end
        end
    end
endmodule