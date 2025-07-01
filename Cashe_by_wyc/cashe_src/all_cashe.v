module icache_one_line(
    //Input
    enable, clk, rst, compare, read, address_in, data_line_in, 
    //Output
    hit, dirty, valid, data_o
    );

    input enable;
    input clk;
    input rst;
    input compare;
    input read;//read-1表示读取；0表示写入
    input[31:0]     address_in;//CPU 请求的 32 位地址
    input[255:0]    data_line_in;//从主内存读取的整个缓存行数据 (256 位，对应 8 个 32 位字)

    output hit;//1表示命中，0表示缺失
    output dirty;//
    output valid;
    output reg[31:0]    data_o;//读取操作时输出的 32 位数据

    reg[255:0]  mem[63:0];
    //addr(32) = tag(21) + index_in_block(6) + addr_in_block(5)
    reg[20:0]   tag[63:0];
    reg         valid_bit[63:0], dirty_bit[63:0];

    wire[20:0]  addr_tag;
    wire[5:0]   addr_index;
    wire[2:0]   addr_in_block;

    assign addr_tag         = address_in[31:11];
    assign addr_index       = address_in[10:5];
    assign addr_in_block    = address_in[4:2];
    //一个缓存行是 2^3 = 8 个 32 位字
    assign hit      = compare == 1 ? (addr_tag == tag[addr_index]? 1'b1 : 1'b0) : 1'b0;
    assign dirty    = dirty_bit[addr_index];
    assign valid    = valid_bit[addr_index];

    integer i;
    initial begin
      for(i = 0; i < 64; i = i + 1) begin
            valid_bit[i] = 0;
            dirty_bit[i] = 0;
            tag[i] = 0;
        end
    end

    always@(negedge clk) begin
        if(enable == 1'b1) begin
            if(rst == 1'b1) begin
                data_o      <= 32'h0;
                for(i = 0; i < 64; i = i + 1) begin
                    valid_bit[i] <= 0;
                end
            end
            else if(read == 1'b1) begin//读操作
                case(addr_in_block)
                    0:  data_o    <=  mem[addr_index][31:0];
                    1:  data_o    <=  mem[addr_index][63:32];
                    2:  data_o    <=  mem[addr_index][95:64];
                    3:  data_o    <=  mem[addr_index][127:96];
                    4:  data_o    <=  mem[addr_index][159:128];
                    5:  data_o    <=  mem[addr_index][191:160];
                    6:  data_o    <=  mem[addr_index][223:192];
                    7:  data_o    <=  mem[addr_index][255:224];
                endcase
            end
            else if(read == 1'b0) begin //写操作
                mem[addr_index] <= data_line_in;
                tag[addr_index] <= addr_tag;
                valid_bit[addr_index] <= 1'b1;
                dirty_bit[addr_index] <= 1'b0;
            end
        end
    end

endmodule

module icache_two_way_group(
    //Input
    enable, clk, rst, compare, read, address_in, data_line_in, 
    //Output
    hit, dirty, valid, data_o
    );

    input           enable, clk, rst, compare, read;
    input[31:0]     address_in;
    input[255:0]    data_line_in;

    output          hit, dirty, valid;
    output[31:0]    data_o;

    wire            enable0, enable1;
    wire            hit0, hit1, dirty0, dirty1, valid0, valid1;
    wire[31:0]      data_o0, data_o1;
    reg             sel;

    initial begin
        sel = 1'b0;
    end
    
    assign hit       = hit0 | hit1;//任一命中，总命中
    assign dirty     = hit0 ? dirty0 : (hit1 ? dirty1 : 0);
    assign valid     = hit0 ? valid0 : (hit1 ? valid1 : 0);
    assign data_o    = hit0 ? data_o0 : (hit1 ? data_o1 : 0);
    assign enable0   = enable & (read |(!read & (!valid0 & valid1 | !sel)));//读操作，两路都被使能；写操作在valid无效时使能，若两路都有效则依靠sel选一路替换
    assign enable1  = enable & (read |(!read & (valid0 & !valid1 | sel)));//
    
    icache_one_line icache_one_line0(
                            .enable(enable0),
                            .clk(clk),
                            .rst(rst),
                            .compare(compare),
                            .read(read),
                            .address_in(address_in),
                            .data_line_in(data_line_in),
                            .hit(hit0),
                            .dirty(dirty0),
                            .valid(valid0),
                            .data_o(data_o0)    
                        );
    
    icache_one_line icache_one_line1(
                            .enable(enable1),
                            .clk(clk),
                            .rst(rst),
                            .compare(compare),
                            .read(read),
                            .address_in(address_in),
                            .data_line_in(data_line_in),
                            .hit(hit1),
                            .dirty(dirty1),
                            .valid(valid1),
                            .data_o(data_o1)    
                        );

    always@(enable or read) begin
        if(enable == 1'b1) begin
            if(read == 1'b0) begin
                sel <= ~sel;//简单伪随机，可以扩展
            end
        end
    end

endmodule

module dcache_one_line(
    //Input
    enable, clk, rst, compare, read, address_in, byte_w_en, data_in, data_line_in,
    //Output
    hit, dirty, valid, data_out, data_line_out, address_out
    );
    input           enable, clk, rst, compare, read;//都和icashe相似
    input[31:0]     address_in, data_in;
    input[3:0]      byte_w_en;//字节写入使能，3-0从高到低控制
    input[255:0]    data_line_in;

    output              hit, dirty, valid;
    output[31:0]        address_out;
    output reg[31:0]    data_out;
    output reg[255:0]   data_line_out;

    reg[255:0]  mem[63:0];
    //addr(32) = tag(21) + index_in_block(6) + addr_in_block(5)
    reg[20:0]   tag[63:0];
    reg         valid_bit[63:0], dirty_bit[63:0];

    wire[20:0]  addr_tag;
    wire[5:0]   addr_index;
    wire[2:0]   addr_in_block;
    integer i;

    assign addr_tag         = address_in[31:11];
    assign addr_index       = address_in[10:5];
    assign addr_in_block    = address_in[4:2];

    initial begin
       for(i = 0; i < 64; i = i + 1) begin
            valid_bit[i] = 1'b0;
            dirty_bit[i] = 1'b0;
            tag[i] = 21'h0;
        end
    end

    assign hit      = compare == 1 ? (addr_tag == tag[addr_index]? 1'b1 : 1'b0) : 1'b0;
    assign dirty    = dirty_bit[addr_index];    
    assign valid    = valid_bit[addr_index];
    assign address_out  = {tag[addr_index], addr_index, 5'b0};
    always@(negedge clk) begin
        if(enable == 1'b1) begin
            if(rst == 1'b1) begin
                data_out <= 32'h0;
                for(i = 0; i < 64; i = i + 1) begin
                    valid_bit[i] = 1'b0;
                end
            end
            else if(read == 1'b1) begin//读操作
                case(addr_in_block)
                    0:  data_out    <=  mem[addr_index][31:0];
                    1:  data_out    <=  mem[addr_index][63:32];
                    2:  data_out    <=  mem[addr_index][95:64];
                    3:  data_out    <=  mem[addr_index][127:96];
                    4:  data_out    <=  mem[addr_index][159:128];
                    5:  data_out    <=  mem[addr_index][191:160];
                    6:  data_out    <=  mem[addr_index][223:192];
                    7:  data_out    <=  mem[addr_index][255:224];
                endcase
                data_line_out <= mem[addr_index];
            end
            else if(read == 1'b0) begin //写操作
                if(compare == 1'b0) begin//未命中
                    dirty_bit[addr_index] <= 1'b0;
                    mem[addr_index] <= data_line_in;
                    tag[addr_index] <= addr_tag;
                    valid_bit[addr_index] <= 1'b1;
                end
                else if(compare == 1'b1 && hit == 1'b1) begin//命中
                    dirty_bit[addr_index] <= 1'b1;
                    case(addr_in_block)
                        0:begin
                            if(byte_w_en[0] == 1'b1) begin mem[addr_index][7:0]      <=  data_in[7:0]; end
                            if(byte_w_en[1] == 1'b1) begin mem[addr_index][15:8]     <=  data_in[15:8]; end
                            if(byte_w_en[2] == 1'b1) begin mem[addr_index][23:16]    <=  data_in[23:16]; end
                            if(byte_w_en[3] == 1'b1) begin mem[addr_index][31:24]    <=  data_in[31:24];  end
                        end
                        1:begin    
                            if(byte_w_en[0] == 1'b1) begin mem[addr_index][39:32]    <=  data_in[7:0]; end
                            if(byte_w_en[1] == 1'b1) begin mem[addr_index][47:40]    <=  data_in[15:8]; end
                            if(byte_w_en[2] == 1'b1) begin mem[addr_index][55:48]    <=  data_in[23:16]; end
                            if(byte_w_en[3] == 1'b1) begin mem[addr_index][63:56]    <=  data_in[31:24];  end
                        end
                        2:begin    
                            if(byte_w_en[0] == 1'b1) begin mem[addr_index][71:64]    <=  data_in[7:0]; end
                            if(byte_w_en[1] == 1'b1) begin mem[addr_index][79:72]    <=  data_in[15:8]; end
                            if(byte_w_en[2] == 1'b1) begin mem[addr_index][87:80]    <=  data_in[23:16]; end
                            if(byte_w_en[3] == 1'b1) begin mem[addr_index][95:88]    <=  data_in[31:24];  end
                        end
                        3:begin    
                            if(byte_w_en[0] == 1'b1) begin mem[addr_index][103:96]   <=  data_in[7:0]; end
                            if(byte_w_en[1] == 1'b1) begin mem[addr_index][111:104]  <=  data_in[15:8]; end
                            if(byte_w_en[2] == 1'b1) begin mem[addr_index][119:112]  <=  data_in[23:16]; end
                            if(byte_w_en[3] == 1'b1) begin mem[addr_index][127:120]  <=  data_in[31:24];  end
                        end
                        4:begin    
                            if(byte_w_en[0] == 1'b1) begin mem[addr_index][135:128]  <= data_in[7:0]; end
                            if(byte_w_en[1] == 1'b1) begin mem[addr_index][143:136]  <= data_in[15:8]; end
                            if(byte_w_en[2] == 1'b1) begin mem[addr_index][151:144]  <= data_in[23:16]; end
                            if(byte_w_en[3] == 1'b1) begin mem[addr_index][159:152]  <= data_in[31:24];  end
                        end                                     
                        5:begin    
                            if(byte_w_en[0] == 1'b1) begin mem[addr_index][167:160]  <= data_in[7:0]; end
                            if(byte_w_en[1] == 1'b1) begin mem[addr_index][175:168]  <= data_in[15:8]; end
                            if(byte_w_en[2] == 1'b1) begin mem[addr_index][183:176]  <= data_in[23:16]; end
                            if(byte_w_en[3] == 1'b1) begin mem[addr_index][191:184]  <= data_in[31:24];  end
                        end                                      
                        6:begin    
                            if(byte_w_en[0] == 1'b1) begin mem[addr_index][199:192]  <= data_in[7:0]; end
                            if(byte_w_en[1] == 1'b1) begin mem[addr_index][207:200]  <= data_in[15:8]; end
                            if(byte_w_en[2] == 1'b1) begin mem[addr_index][215:208]  <= data_in[23:16]; end
                            if(byte_w_en[3] == 1'b1) begin mem[addr_index][223:216]  <= data_in[31:24];  end
                        end                                      
                        7:begin    
                            if(byte_w_en[0] == 1'b1) begin mem[addr_index][231:224]  <= data_in[7:0]; end
                            if(byte_w_en[1] == 1'b1) begin mem[addr_index][239:232]  <= data_in[15:8]; end
                            if(byte_w_en[2] == 1'b1) begin mem[addr_index][247:240]  <= data_in[23:16]; end
                            if(byte_w_en[3] == 1'b1) begin mem[addr_index][255:248]  <= data_in[31:24];  end
                        end                                      
                            
                    endcase          
                    
                end
            end
        end
    end

endmodule

module dcache_two_way_group(
    //Input
    enable, clk, rst, compare, read, address_in, byte_w_en, data_in, data_line_in,
    //Output
    hit, dirty, valid, data_out, data_line_out, address_out
    );
    input           enable, clk, rst, compare, read;
    input[31:0]     address_in, data_in;
    input[3:0]      byte_w_en;
    input[255:0]    data_line_in;

    output              hit, dirty, valid;
    output[31:0]        data_out;
    output[31:0]        address_out;
    output[255:0]       data_line_out;

    wire            enable0, enable1;
    wire            hit0, hit1, dirty0, dirty1, valid0, valid1;
    wire[31:0]      data_out0, data_out1, address_out0, address_out1;
    wire[255:0]     data_line_out0, data_line_out1;

    reg sel;
    initial begin
        sel = 1'b0;
    end
    assign hit = hit0 | hit1;
    assign dirty = hit0 ? dirty0 : (hit1 ? dirty1 : (sel ? dirty1 : dirty0));
    assign valid = hit0 ? valid0 : (hit1 ? valid1 : (sel ? valid1 : valid0));
    assign address_out = enable0 ? address_out0: (enable1 ? address_out1: (sel ? address_out1 : address_out0));
    assign data_line_out = hit0 ? data_line_out0 : (hit1 ? data_line_out1 : (sel ? data_line_out1 : data_line_out0));
    assign data_out = hit0 ? data_out0 : (hit1 ? data_out1 : 0);
    assign enable0 = enable & (compare | !read & (!valid0 & valid1 | !sel));//完全类似的组相联
    assign enable1 = enable & (compare | !read & (!valid1 & valid0 |  sel));
    dcache_one_line     dcache_one_line0(
                            .enable(enable0),
                            .clk(clk),
                            .rst(rst),
                            .compare(compare),
                            .read(read),
                            .address_in(address_in),
                            .byte_w_en(byte_w_en),
                            .data_in(data_in),
                            .data_line_in(data_line_in),
                            .hit(hit0),
                            .dirty(dirty0),
                            .valid(valid0),
                            .data_out(data_out0),
                            .data_line_out(data_line_out0),
                            .address_out(address_out0)
                        );

    dcache_one_line     dcache_one_line1(
                            .enable(enable1),
                            .clk(clk),
                            .rst(rst),
                            .compare(compare),
                            .read(read),
                            .address_in(address_in),
                            .byte_w_en(byte_w_en),
                            .data_in(data_in),
                            .data_line_in(data_line_in),
                            .hit(hit1),
                            .dirty(dirty1),
                            .valid(valid1),
                            .data_out(data_out1),
                            .data_line_out(data_line_out1),
                            .address_out(address_out1)
                        );


    always@(enable or read or compare) begin
       if(enable == 1'b1) begin
           if(read == 1'b1) begin
               if(compare == 1'b0) begin
                   sel = ~sel;
               end
           end
       end
    end

endmodule