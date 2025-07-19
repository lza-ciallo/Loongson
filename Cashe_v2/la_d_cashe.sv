interface cpu_cache_if (input logic clk, rst_n);
    // CPU -> Cache
    logic        req_valid;
    logic [31:0] req_addr;
    logic        req_wen;          // 1写，0读
    logic [31:0] req_wdata;
    logic [3:0]  req_wstrb;        // 写使能
    logic        req_is_cacop;     // cacop的接口
    logic        req_is_preload;   
    logic [4:0]  req_cacop_op;     // cacop的5bit code
    
    // Cache -> CPU
    logic        req_ready;        // Cache允许接受新请求
    logic        resp_valid;       // Cache有可用data
    logic [31:0] resp_rdata;
    logic        stall;            

    modport CPU (
        output req_valid, req_addr, req_wen, req_wdata, req_wstrb, 
               req_is_cacop, req_is_preload, req_cacop_op,
        input  req_ready, resp_valid, resp_rdata, stall
    );
    
    modport Cache (
        input  req_valid, req_addr, req_wen, req_wdata, req_wstrb,
               req_is_cacop, req_is_preload, req_cacop_op,
        output req_ready, resp_valid, resp_rdata, stall,
        input clk, rst_n
    );
endinterface

// Interface: Cache <-> Main Memory
interface cache_mem_if (input logic clk, rst_n);
    // Cache -> Memory
    logic        req_valid;
    logic [31:0] req_addr;
    logic        req_wen;           // 写使能信号 (1 = 写回脏块, 0 = 填充新行)
    logic [255:0] req_wdata;       // Write data (entire cache line)

    // Memory -> Cache
    logic        req_ready;       
    logic        resp_valid;
    logic [255:0] resp_rdata;      
    
    modport Cache (
        output req_valid, req_addr, req_wen, req_wdata,
        input  req_ready, resp_valid, resp_rdata,
        input clk, rst_n
    );
    
    modport Memory (
        input  req_valid, req_addr, req_wen, req_wdata,
        output req_ready, resp_valid, resp_rdata,
        input clk, rst_n
    );
endinterface


module la_d_cache (
    cpu_cache_if.Cache cpu_if,
    cache_mem_if.Cache mem_if
);

    // -- Cache Parameters --
    localparam CACHE_LINES          = 256;         // Cache行数
    localparam CACHE_LINE_SIZE_BYTES = 32;          // 每行32字节
    
    localparam OFFSET_WIDTH         = $clog2(CACHE_LINE_SIZE_BYTES); // 行内偏移量
    localparam INDEX_WIDTH          = $clog2(CACHE_LINES);           // 索引位宽
    localparam TAG_WIDTH            = 32 - INDEX_WIDTH - OFFSET_WIDTH; // 标签位宽
    localparam CACHE_LINE_SIZE_BITS = CACHE_LINE_SIZE_BYTES * 8;
    
    // LoongArch CACOP operation codes (example)
    localparam CACOP_OP_I_WBI = 5'b00001; // Index Write-Back Invalidate

    // -- State Machine Definition --
    typedef enum logic [3:0] {
        IDLE,// 0: 空闲状态，等待CPU请求
        LOOKUP,// 1: 查找与比较状态
        READ_HIT,// 2: 读命中
        WRITE_HIT,// 3: 写命中
        MISS_EVICT,// 4: 未命中且需写回脏块
        MISS_REFILL,// 5: 未命中，从主存填充数据 
        CACOP_EXEC,// 6: 执行 cacop 指令
        PRELOAD_REFILL,// 7: 执行 preload，后台填充数据
        CACOP_EVICT_WAIT // 8: 等待Cacop写回完成
    } state_t;

    state_t current_state, next_state;

    // -- Cache Storage Arrays --
    logic [TAG_WIDTH-1:0]              tag_array   [CACHE_LINES-1:0];
    logic [CACHE_LINE_SIZE_BITS-1:0]   data_array  [CACHE_LINES-1:0];
    logic                              valid_array [CACHE_LINES-1:0];
    logic                              dirty_array [CACHE_LINES-1:0];// 脏位阵列


    logic [31:0] proc_addr;
    logic        proc_wen;
    logic [31:0] proc_wdata;
    logic [3:0]  proc_wstrb;
    logic        proc_is_cacop;
    logic        proc_is_preload;
    logic [4:0]  proc_cacop_op;
    
    //地址分解
    logic [TAG_WIDTH-1:0]   addr_tag;
    logic [INDEX_WIDTH-1:0] addr_index;
    logic [OFFSET_WIDTH-1:0] addr_offset;

    assign addr_tag    = proc_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];
    assign addr_index  = proc_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign addr_offset = proc_addr[OFFSET_WIDTH - 1 : 0];

    // 命中/未命中判断逻辑
    logic hit;
    logic target_line_valid;
    logic target_line_dirty;
    
    assign target_line_valid = valid_array[addr_index];
    assign target_line_dirty = dirty_array[addr_index];
    assign hit = target_line_valid && (tag_array[addr_index] == addr_tag);

    // 读写数据路径
    logic [CACHE_LINE_SIZE_BITS-1:0] line_rdata;
    logic [CACHE_LINE_SIZE_BITS-1:0] line_wdata;

    
    assign line_rdata = data_array[addr_index];//从数据阵列中读出整个缓存行

 
    always_comb begin
        //在没有写操作或字节未被选通时，数据保持不变。
        line_wdata = line_rdata;

        case (addr_offset[4:2])
            // --- 更新第0个字 (bits [31:0]) ---
            3'd0: begin
                if (proc_wstrb[0]) line_wdata[7:0]   = proc_wdata[7:0];
                if (proc_wstrb[1]) line_wdata[15:8]  = proc_wdata[15:8];
                if (proc_wstrb[2]) line_wdata[23:16] = proc_wdata[23:16];
                if (proc_wstrb[3]) line_wdata[31:24] = proc_wdata[31:24];
            end
            
            // --- 更新第1个字 (bits [63:32]) ---
            3'd1: begin
                if (proc_wstrb[0]) line_wdata[39:32] = proc_wdata[7:0];
                if (proc_wstrb[1]) line_wdata[47:40] = proc_wdata[15:8];
                if (proc_wstrb[2]) line_wdata[55:48] = proc_wdata[23:16];
                if (proc_wstrb[3]) line_wdata[63:56] = proc_wdata[31:24];
            end

            // --- 更新第2个字 (bits [95:64]) ---
            3'd2: begin
                if (proc_wstrb[0]) line_wdata[71:64] = proc_wdata[7:0];
                if (proc_wstrb[1]) line_wdata[79:72] = proc_wdata[15:8];
                if (proc_wstrb[2]) line_wdata[87:80] = proc_wdata[23:16];
                if (proc_wstrb[3]) line_wdata[95:88] = proc_wdata[31:24];
            end
            
            // --- 更新第3个字 (bits [127:96]) ---
            3'd3: begin
                if (proc_wstrb[0]) line_wdata[103:96]  = proc_wdata[7:0];
                if (proc_wstrb[1]) line_wdata[111:104] = proc_wdata[15:8];
                if (proc_wstrb[2]) line_wdata[119:112] = proc_wdata[23:16];
                if (proc_wstrb[3]) line_wdata[127:120] = proc_wdata[31:24];
            end

            // --- 更新第4个字 (bits [159:128]) ---
            3'd4: begin
                if (proc_wstrb[0]) line_wdata[135:128] = proc_wdata[7:0];
                if (proc_wstrb[1]) line_wdata[143:136] = proc_wdata[15:8];
                if (proc_wstrb[2]) line_wdata[151:144] = proc_wdata[23:16];
                if (proc_wstrb[3]) line_wdata[159:152] = proc_wdata[31:24];
            end

            // --- 更新第5个字 (bits [191:160]) ---
            3'd5: begin
                if (proc_wstrb[0]) line_wdata[167:160] = proc_wdata[7:0];
                if (proc_wstrb[1]) line_wdata[175:168] = proc_wdata[15:8];
                if (proc_wstrb[2]) line_wdata[183:176] = proc_wdata[23:16];
                if (proc_wstrb[3]) line_wdata[191:184] = proc_wdata[31:24];
            end

            // --- 更新第6个字 (bits [223:192]) ---
            3'd6: begin
                if (proc_wstrb[0]) line_wdata[199:192] = proc_wdata[7:0];
                if (proc_wstrb[1]) line_wdata[207:200] = proc_wdata[15:8];
                if (proc_wstrb[2]) line_wdata[215:208] = proc_wdata[23:16];
                if (proc_wstrb[3]) line_wdata[223:216] = proc_wdata[31:24];
            end

            // --- 更新第7个字 (bits [255:224]) ---
            3'd7: begin
                if (proc_wstrb[0]) line_wdata[231:224] = proc_wdata[7:0];
                if (proc_wstrb[1]) line_wdata[239:232] = proc_wdata[15:8];
                if (proc_wstrb[2]) line_wdata[247:240] = proc_wdata[23:16];
                if (proc_wstrb[3]) line_wdata[255:248] = proc_wdata[31:24];
            end
            
            default: begin
            end
        endcase
    end


    // 状态
    always_ff @(posedge cpu_if.clk or negedge cpu_if.rst_n) begin
        if (!cpu_if.rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // 当Cache空闲且CPU有新请求时，锁存请求的所有信息
    always_ff @(posedge cpu_if.clk) begin
        if (current_state == IDLE && cpu_if.req_valid) begin
            proc_addr      <= cpu_if.req_addr;
            proc_wen       <= cpu_if.req_wen;
            proc_wdata     <= cpu_if.req_wdata;
            proc_wstrb     <= cpu_if.req_wstrb;
            proc_is_cacop  <= cpu_if.req_is_cacop;
            proc_is_preload<= cpu_if.req_is_preload;
            proc_cacop_op  <= cpu_if.req_cacop_op;
        end
    end

    // 状态机逻辑
    always_comb begin
        next_state = current_state;
        

        cpu_if.req_ready  = 1'b0;
        cpu_if.resp_valid = 1'b0;
        cpu_if.stall      = 1'b1;
        cpu_if.resp_rdata = 'x;

        mem_if.req_valid = 1'b0;
        mem_if.req_addr  = 'x;
        mem_if.req_wen   = 1'b0;
        mem_if.req_wdata = 'x;

        case (current_state)
            IDLE: begin
                cpu_if.stall = 1'b0;
                cpu_if.req_ready = 1'b1;// 并表示可以接收新请求
                if (cpu_if.req_valid) begin
                    next_state = LOOKUP;// 收到新请求，进入查找状态
                end
            end

            LOOKUP: begin
                if (proc_is_cacop) begin
                    next_state = CACOP_EXEC;
                end else if (proc_is_preload) begin
                    if (!hit) begin  // 仅当未命中时才需要处理 preload
                        if (target_line_dirty) next_state = MISS_EVICT;// 如果行是脏的，先写回
                        else next_state = PRELOAD_REFILL;
                    end else begin 
                        next_state = IDLE;
                    end
                end else begin // 普通的读/写请求
                    if (hit) begin
                        next_state = proc_wen ? WRITE_HIT : READ_HIT;// 命中，根据读写进入相应状态
                    end else begin // Miss
                        if (target_line_dirty) next_state = MISS_EVICT;// 如果行是脏的，先写回
                        else next_state = MISS_REFILL;
                    end
                end
            end

            READ_HIT: begin
                cpu_if.resp_valid = 1'b1;
                 // 根据字偏移量从缓存行中选择正确的32位数据返回给CPU
                cpu_if.resp_rdata = line_rdata >> (addr_offset[OFFSET_WIDTH-1:2] * 32);
                next_state = IDLE;
            end

            WRITE_HIT: begin
                cpu_if.resp_valid = 1'b1;  // 发出完成信号。实际的写入操作在下一个时钟周期的时序逻辑中完成。
                next_state = IDLE;
            end

            MISS_EVICT: begin 
                mem_if.req_valid = 1'b1;
                mem_if.req_wen   = 1'b1;
                // 构造被替换行的物理地址
                mem_if.req_addr  = {tag_array[addr_index], addr_index, {OFFSET_WIDTH{1'b0}}};
                mem_if.req_wdata = data_array[addr_index];
                
                if (mem_if.req_ready) begin
                    // 写回请求已发出，接下来根据原始请求类型决定是填充普通数据还是预取数据
                    next_state = proc_is_preload ? PRELOAD_REFILL : MISS_REFILL;
                    end else begin
                    // 主存不ready，保持在EVICT状态重试，也许这里需要再定义一个状态？
                   next_state = MISS_EVICT;
                    end
            end
            
            MISS_REFILL: begin // Read new line from main memory
                mem_if.req_valid = 1'b1;
                mem_if.req_wen   = 1'b0;
                mem_if.req_addr  = {addr_tag, addr_index, {OFFSET_WIDTH{1'b0}}};
                
                if (mem_if.resp_valid) begin
                     // 数据已返回，将在时序逻辑中更新Cache。
                    // 返回 LOOKUP 状态，必定命中。
                    next_state = LOOKUP; 
                end
            end

            PRELOAD_REFILL: begin
                //主要区别是不阻塞流水线
                mem_if.req_valid = 1'b1;
                mem_if.req_wen   = 1'b0;
                mem_if.req_addr  = {addr_tag, addr_index, {OFFSET_WIDTH{1'b0}}};
                
                if (mem_if.resp_valid) begin
                    next_state = IDLE;
                end
            end

             CACOP_EXEC: begin
                next_state = IDLE;
                cpu_if.resp_valid = 1'b1;

                if (proc_cacop_op[2:0] == 3'b001) begin // 目标是D-Cache
                    case (proc_cacop_op[4:3])
                        2'b00: begin // 类型0: 初始化                    
                        end
                        2'b01: begin // 类型1: 索引维护
                            if (target_line_dirty && target_line_valid) begin
                                mem_if.req_valid = 1'b1;
                                mem_if.req_wen   = 1'b1;
                                mem_if.req_addr  = {tag_array[addr_index], addr_index, {OFFSET_WIDTH{1'b0}}};
                                mem_if.req_wdata = data_array[addr_index];
                                cpu_if.resp_valid = 1'b0;
                                if (mem_if.req_ready) begin
                                    next_state = CACOP_EVICT_WAIT;
                                end else begin
                                    next_state = CACOP_EXEC;
                                end
                            end
                        end
                        2'b10: begin // 类型2: 命中维护
                            if (hit) begin
                                if (target_line_dirty) begin
                                    mem_if.req_valid = 1'b1;
                                    mem_if.req_wen   = 1'b1;
                                    mem_if.req_addr  = {tag_array[addr_index], addr_index, {OFFSET_WIDTH{1'b0}}};
                                    mem_if.req_wdata = data_array[addr_index];
                                    cpu_if.resp_valid = 1'b0;
                                    if (mem_if.req_ready) begin
                                        next_state = CACOP_EVICT_WAIT;
                                    end else begin
                                        next_state = CACOP_EXEC;
                                    end
                                end
                            end
                        end
                        default: begin
                            // 类型3或其他，忽略
                        end
                    endcase
                end
            end
            
            CACOP_EVICT_WAIT: begin
                cpu_if.resp_valid = 1'b0;
                if (mem_if.req_ready) begin // 假设主存写完后，req_ready会再次变高
                    cpu_if.resp_valid = 1'b1;
                    next_state = IDLE;
                end else begin
                    next_state = CACOP_EVICT_WAIT;
                end
            end

        endcase
    end
    
    // 时序逻辑
    always_ff @(posedge cpu_if.clk) begin
        logic [CACHE_LINE_SIZE_BITS-1:0] new_line_data;
        // 写命中：在WRITE_HIT状态的下一个周期，更新数据阵列和脏位
        if (current_state == WRITE_HIT) begin
            data_array[addr_index] <= line_wdata;
            dirty_array[addr_index] <= 1'b1;
        end
        // 普通未命中填充：当主存数据在MISS_REFILL状态返回时，更新整个缓存行
        if (current_state == MISS_REFILL && mem_if.resp_valid) begin
            new_line_data = mem_if.resp_rdata;
            valid_array[addr_index] <= 1'b1;
            tag_array[addr_index]   <= addr_tag;
            // 在写分配时，需要基于新取回的数据进行修改
            if(proc_wen) begin
                 case (addr_offset[4:2])
                    3'd0: begin
                        if (proc_wstrb[0]) new_line_data[7:0]   = proc_wdata[7:0];
                        if (proc_wstrb[1]) new_line_data[15:8]  = proc_wdata[15:8];
                        if (proc_wstrb[2]) new_line_data[23:16] = proc_wdata[23:16];
                        if (proc_wstrb[3]) new_line_data[31:24] = proc_wdata[31:24];
                    end
                    3'd1: begin
                        if (proc_wstrb[0]) new_line_data[39:32] = proc_wdata[7:0];
                        if (proc_wstrb[1]) new_line_data[47:40] = proc_wdata[15:8];
                        if (proc_wstrb[2]) new_line_data[55:48] = proc_wdata[23:16];
                        if (proc_wstrb[3]) new_line_data[63:56] = proc_wdata[31:24];
                    end
                     3'd2: begin
                if (proc_wstrb[0]) new_line_data[71:64] = proc_wdata[7:0];
                if (proc_wstrb[1]) new_line_data[79:72] = proc_wdata[15:8];
                if (proc_wstrb[2]) new_line_data[87:80] = proc_wdata[23:16];
                if (proc_wstrb[3]) new_line_data[95:88] = proc_wdata[31:24];
            end
            
            
            3'd3: begin
                if (proc_wstrb[0]) new_line_data[103:96]  = proc_wdata[7:0];
                if (proc_wstrb[1]) new_line_data[111:104] = proc_wdata[15:8];
                if (proc_wstrb[2]) new_line_data[119:112] = proc_wdata[23:16];
                if (proc_wstrb[3]) new_line_data[127:120] = proc_wdata[31:24];
            end

 
            3'd4: begin
                if (proc_wstrb[0]) new_line_data[135:128] = proc_wdata[7:0];
                if (proc_wstrb[1]) new_line_data[143:136] = proc_wdata[15:8];
                if (proc_wstrb[2]) new_line_data[151:144] = proc_wdata[23:16];
                if (proc_wstrb[3]) new_line_data[159:152] = proc_wdata[31:24];
            end


            3'd5: begin
                if (proc_wstrb[0]) new_line_data[167:160] = proc_wdata[7:0];
                if (proc_wstrb[1]) new_line_data[175:168] = proc_wdata[15:8];
                if (proc_wstrb[2]) new_line_data[183:176] = proc_wdata[23:16];
                if (proc_wstrb[3]) new_line_data[191:184] = proc_wdata[31:24];
            end

            3'd6: begin
                if (proc_wstrb[0]) new_line_data[199:192] = proc_wdata[7:0];
                if (proc_wstrb[1]) new_line_data[207:200] = proc_wdata[15:8];
                if (proc_wstrb[2]) new_line_data[215:208] = proc_wdata[23:16];
                if (proc_wstrb[3]) new_line_data[223:216] = proc_wdata[31:24];
            end

            3'd7: begin
                if (proc_wstrb[0]) new_line_data[231:224] = proc_wdata[7:0];
                if (proc_wstrb[1]) new_line_data[239:232] = proc_wdata[15:8];
                if (proc_wstrb[2]) new_line_data[247:240] = proc_wdata[23:16];
                if (proc_wstrb[3]) new_line_data[255:248] = proc_wdata[31:24];
            end

                    endcase
                 
                dirty_array[addr_index] <= 1'b1; // 置脏
            end else begin
                dirty_array[addr_index] <= 1'b0;
                
            end
            data_array[addr_index] <= new_line_data;
        end
        // 增加对PRELOAD_REFILL的处理
        if (current_state == PRELOAD_REFILL && mem_if.resp_valid) begin
            valid_array[addr_index] <= 1'b1;
            dirty_array[addr_index] <= 1'b0;
            tag_array[addr_index]   <= addr_tag;
            data_array[addr_index]  <= mem_if.resp_rdata;
        end
        
        if (current_state == CACOP_EXEC && next_state == IDLE) begin // 单周期完成的cacop
            if (proc_cacop_op[2:0] == 3'b001) begin // 确认目标是D-Cache
                case (proc_cacop_op[4:3])
                    2'b00: begin // 初始化
                        tag_array[addr_index]   <= '0;
                        valid_array[addr_index] <= 1'b0;
                        dirty_array[addr_index] <= 1'b0;
                    end
                    2'b01: begin // 索引维护 (不脏的情况)
                        if (!target_line_dirty) begin
                            valid_array[addr_index] <= 1'b0;
                        end
                    end
                    2'b10: begin // 命中维护 (不脏且命中的情况)
                        if (hit && !target_line_dirty) begin
                            valid_array[addr_index] <= 1'b0;
                        end
                    end
                    
                endcase
            end
        end else if (current_state == CACOP_EVICT_WAIT && next_state == IDLE) begin 
            // 写回完成后，无效化
            valid_array[addr_index] <= 1'b0;
            dirty_array[addr_index] <= 1'b0;
        end
    end

    // Reset
    always_ff @(posedge cpu_if.clk or negedge cpu_if.rst_n) begin
        if (!cpu_if.rst_n) begin
            for (integer i = 0; i < CACHE_LINES; i = i + 1) begin
                valid_array[i] <= 1'b0;
                dirty_array[i] <= 1'b0;
            end
        end
    end

endmodule