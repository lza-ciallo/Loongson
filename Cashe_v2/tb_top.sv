// =================================================================
// Testbench Top: tb_top.sv (增强测试版)
// 1. 初始化主存，避免读出 'x'
// 2. 添加了全面的 cacop 指令测试场景
// =================================================================

`timescale 1ns / 1ps

module tb_top;

    // --- 1. 时钟和复位信号 ---
    reg clk;
    reg rst_n;

    // --- 2. 实例化接口 ---
    cpu_cache_if cpu_bus(clk, rst_n);
    cache_mem_if mem_bus(clk, rst_n);

    // --- 3. 实例化被测设计 (DUT) ---
    la_d_cache dut (
        .cpu_if(cpu_bus.Cache),
        .mem_if(mem_bus.Cache)
    );

    // --- 4. 简易主存模型 ---
    localparam MEM_SIZE = 16 * 1024 * 1024;
    localparam MEM_LATENCY = 5;
    reg [7:0] main_memory [0:MEM_SIZE-1];

    always @(posedge clk) begin
        reg [31:0] addr;
        reg [255:0] read_data;
    
        if (!rst_n) begin
            mem_bus.req_ready <= 1'b1;
            mem_bus.resp_valid <= 1'b0;
        end else begin
            mem_bus.req_ready <= 1'b1;

            if (mem_bus.req_valid && mem_bus.req_ready) begin
                addr = mem_bus.req_addr;
                mem_bus.req_ready <= 1'b0;

                if (mem_bus.req_wen) begin
                    $display("[%0t] TB_MEM: Received WRITE request for addr 0x%h", $time, addr);
                    repeat(MEM_LATENCY) @(posedge clk);
                    for (int i = 0; i < 32; i++) begin
                        main_memory[addr + i] = mem_bus.req_wdata[i*8 +: 8];
                    end
                    $display("[%0t] TB_MEM: Write to 0x%h complete.", $time, addr);
                    mem_bus.req_ready <= 1'b1;
                end else begin
                    $display("[%0t] TB_MEM: Received READ request for addr 0x%h", $time, addr);
                    for (int i = 0; i < 32; i++) begin
                        read_data[i*8 +: 8] = main_memory[addr + i];
                    end
                    repeat(MEM_LATENCY) @(posedge clk);
                    mem_bus.resp_rdata <= read_data;
                    mem_bus.resp_valid <= 1'b1;
                    $display("[%0t] TB_MEM: Responding with data for 0x%h.", $time, addr);
                end
            end else if (mem_bus.resp_valid) begin
                mem_bus.resp_valid <= 1'b0;
            end
        end
    end

    // --- 5. CPU 模型和测试序列 ---
    initial begin
        clk = 0;
        rst_n = 0;
        cpu_bus.req_valid <= 0;

        // --- BUG 1 修复: 初始化主存 ---
        $display("Initializing main memory to zero...");
        for (integer i = 0; i < MEM_SIZE; i = i + 1) begin
            main_memory[i] = 8'h00;
        end

        // 预先填充一些内存数据用于测试
        main_memory[32'h1000_0000 + 0] = 8'hAA;
        main_memory[32'h1000_0000 + 1] = 8'hBB;
        main_memory[32'h1000_0000 + 2] = 8'hCC;
        main_memory[32'h1000_0000 + 3] = 8'hDD;

        $display("------------- TEST START -------------");
        repeat(2) @(posedge clk);
        rst_n = 1;
        $display("[%0t] TB_CPU: Reset released.", $time);
        
        // --- 测试场景 ---
        $display("\n--- SCENARIO 1: Read Miss -> Read Hit ---");
        cpu_read_req(32'h1000_0000); // 读Miss
        cpu_read_req(32'h1000_0004); // 读Hit (同一行，但从未初始化的内存读，现在应为0)

        $display("\n--- SCENARIO 2: Write Miss (Allocate) -> Write Hit -> Eviction ---");
        // 地址 2xxxxxxx 和 3xxxxxxx 映射到不同行
        cpu_write_req(32'h2000_1000, 32'hDEADBEEF, 4'b1111); // 写Miss，使行变脏
        cpu_read_req(32'h2000_1000); // 读Hit
        // 访问一个会导致行替换的地址 (index不同)，触发脏块写回
        cpu_read_req(32'h3000_2000); 

        // --- 新增: 全面 CACOP 测试 ---
        $display("\n--- SCENARIO 3: Comprehensive CACOP Test ---");
        
        // --- 3.1 测试类型0: Cache 初始化 (Store Tag) ---
        $display("\n--- 3.1 Cacop Type 0: Store Tag (op=5'b00001) ---");
        // 先填充一个Cache行
        cpu_write_req(32'h7000_0000, 32'hCAFEBABE, 4'b1111);
        $display("TB_CPU: Before cacop, reading back to confirm data is present.");
        cpu_read_req(32'h7000_0000); // 确认数据在Cache中
        // 执行 cacop 初始化操作
        cpu_cacop_req(32'h7000_0000, 5'b00001);
        $display("TB_CPU: After cacop, reading again. Should be a MISS.");
        cpu_read_req(32'h7000_0000); // 再次读，应触发Miss，且读回主存的0
        
        // --- 3.2 测试类型1: 索引维护 (不脏的情况) ---
        $display("\n--- 3.2 Cacop Type 1: Index Invalidate [Clean] (op=5'b01001) ---");
        // 先填充一个干净行
        cpu_read_req(32'h1000_0000); 
        $display("TB_CPU: Before cacop, reading to confirm data is present.");
        cpu_read_req(32'h1000_0000); // 确认是Hit
        // 执行索引无效化
        cpu_cacop_req(32'h1000_0000, 5'b01001);
        $display("TB_CPU: After cacop, reading again. Should be a MISS.");
        cpu_read_req(32'h1000_0000); // 应触发Miss

        // --- 3.3 测试类型1: 索引维护 (脏的情况) ---
        $display("\n--- 3.3 Cacop Type 1: Index Write-Back & Invalidate [Dirty] (op=5'b01001) ---");
        // 地址 8xxxxxxx 和 9xxxxxxx 映射到同一个index
        cpu_write_req(32'h8000_3000, 32'hFEEDF00D, 4'b1111); // 使该行变脏
        // 对另一个tag但相同index的地址执行 cacop，效果一样
        cpu_cacop_req(32'h9000_3000, 5'b01001); // 应触发写回，并无效化
        $display("TB_CPU: After cacop, reading original addr. Should be a MISS but data should be in memory.");
        cpu_read_req(32'h8000_3000); // 读回，应触发Miss，但能从主存读回 0xFEEDF00D
        
        // --- 3.4 测试类型2: 命中维护 (Hit Invalidate) ---
        $display("\n--- 3.4 Cacop Type 2: Hit Invalidate (op=5'b10001) ---");
        // 准备两个地址，一个在Cache中，一个不在
        cpu_read_req(32'hA000_4000); // 地址A在Cache中
        // 对不在Cache中的地址B执行Hit Invalidate，应无任何操作
        $display("TB_CPU: Executing Hit-Invalidate on a MISS address. Should do nothing.");
        cpu_cacop_req(32'hB000_4000, 5'b10001);
        $display("TB_CPU: Reading address A again. Should still be a HIT.");
        cpu_read_req(32'hA000_4000); // 读A，仍应是Hit
        // 对在Cache中的地址A执行Hit Invalidate
        $display("TB_CPU: Executing Hit-Invalidate on a HIT address. Should invalidate.");
        cpu_cacop_req(32'hA000_4000, 5'b10001);
        $display("TB_CPU: Reading address A again. Should now be a MISS.");
        cpu_read_req(32'hA000_4000); // 读A，现在应是Miss

        // 结束仿真
        repeat(20) @(posedge clk);
        $display("\n------------- TEST END -------------");
        $finish;
    end

    // --- 时钟生成 ---
    always #5 clk = ~clk;

    // --- CPU 请求任务 (保持最终修正版不变) ---
    task cpu_read_req(input [31:0] addr);
        $display("[%0t] TB_CPU: Issuing READ request for addr 0x%h", $time, addr);
        cpu_bus.req_valid <= 1'b1;
        cpu_bus.req_wen   <= 1'b0;
        cpu_bus.req_addr  <= addr;
        cpu_bus.req_is_cacop <= 1'b0;
        cpu_bus.req_is_preload <= 1'b0;
        do begin
            @(posedge clk);
        end while (cpu_bus.req_ready == 1'b0);
        cpu_bus.req_valid <= 1'b0;
        while (cpu_bus.resp_valid == 1'b0) begin
            @(posedge clk);
        end
        $display("[%0t] TB_CPU: Read data 0x%h from Cache for addr 0x%h", $time, cpu_bus.resp_rdata, addr);
        @(posedge clk);
    endtask

    task cpu_write_req(input [31:0] addr, input [31:0] wdata, input [3:0] wstrb);
        $display("[%0t] TB_CPU: Issuing WRITE request for addr 0x%h with data 0x%h", $time, addr, wdata);
        cpu_bus.req_valid <= 1'b1;
        cpu_bus.req_wen   <= 1'b1;
        cpu_bus.req_addr  <= addr;
        cpu_bus.req_wdata <= wdata;
        cpu_bus.req_wstrb <= wstrb;
        cpu_bus.req_is_cacop <= 1'b0;
        cpu_bus.req_is_preload <= 1'b0;
        do begin
            @(posedge clk);
        end while (cpu_bus.req_ready == 1'b0);
        cpu_bus.req_valid <= 1'b0;
        while (cpu_bus.resp_valid == 1'b0) begin
            @(posedge clk);
        end
        $display("[%0t] TB_CPU: Write to addr 0x%h complete.", $time, addr);
        @(posedge clk);
    endtask
    
    task cpu_preload_req(input [31:0] addr);
        $display("[%0t] TB_CPU: Issuing PRELOAD request for addr 0x%h", $time, addr);
        cpu_bus.req_valid <= 1'b1;
        cpu_bus.req_addr  <= addr;
        cpu_bus.req_is_preload <= 1'b1;
        cpu_bus.req_is_cacop <= 1'b0;
        cpu_bus.req_wen <= 1'b0;
        do begin
            @(posedge clk);
        end while (cpu_bus.req_ready == 1'b0);
        cpu_bus.req_valid <= 1'b0;
        @(posedge clk);
    endtask

    task cpu_cacop_req(input [31:0] addr, input [4:0] op);
        $display("[%0t] TB_CPU: Issuing CACOP request for addr 0x%h, op=0x%h", $time, addr, op);
        cpu_bus.req_valid <= 1'b1;
        cpu_bus.req_addr  <= addr;
        cpu_bus.req_is_cacop <= 1'b1;
        cpu_bus.req_cacop_op <= op;
        cpu_bus.req_is_preload <= 1'b0;
        do begin
            @(posedge clk);
        end while (cpu_bus.req_ready == 1'b0);
        cpu_bus.req_valid <= 1'b0;
        while (cpu_bus.resp_valid == 1'b0) begin
            @(posedge clk);
        end
        $display("[%0t] TB_CPU: Cacop op 0x%h complete.", $time, op);
        @(posedge clk);
    endtask

endmodule