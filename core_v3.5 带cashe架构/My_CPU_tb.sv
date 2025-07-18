`timescale 1ns / 1ps

// ===================================================================
//      Final Top-Level Testbench for My_CPU (Verilog-2001)
// ===================================================================
module My_CPU_tb;

    // --- Parameters ---
    parameter CLK_PERIOD = 10;

    // --- Signals ---
    reg clk;
    reg rst;

    // --- Instantiate the DUT ---
    My_CPU uut (
        .clk(clk),
        .rst(rst)
    );

    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end
    
    // --- (可选) 监视写回主存的行为 ---
    // Verilog-2001 中没有 string, 我们直接打印
    initial begin
        // Wait for reset to be released
        @(posedge rst);
        @(negedge rst);
        forever @(posedge clk) begin
            // 当 cache 向主存发起写请求时 (通常是 write-back)
            // 需要使用层次化引用访问 DUT 内部的 wire
            if (uut.ram_en && uut.ram_write) begin
                $display("T=%0t: [MEMORY MONITOR] Write-Back to Main Memory detected!", $time);
                $display("\t Addr: 0x%h, Data[255:224]: 0x%h", uut.ram_addr, uut.ram_wdata[255:224]);
            end
        end
    end

    // --- Test Sequence ---
    initial begin
        // 1. 打印开始信息
        $display("-------------------------------------------------");
        $display("T=%0t: [INFO] Testbench Started. Assumes program.coe is pre-loaded into BRAM.", $time);
        
        // 2. 施加复位
        rst = 1'b1;
        repeat(5) @(posedge clk);
        $display("T=%0t: [INFO] Applying Reset.", $time);
        
        // 3. 释放复位，CPU开始运行
        rst = 1'b0;
        @(posedge clk);
        $display("T=%0t: [INFO] Reset Released. CPU starts execution.", $time);
        
        // 4. 让仿真运行足够长的时间来完成程序
        repeat(500) @(posedge clk);
        
        // 5. 检查最终结果
        $display("\n------------------[ FINAL STATE CHECK ]------------------");
        
        // 检查寄存器 r5。期望值: 10 + 20 = 30
        // 你必须用你自己的、正确的层次化路径替换下面的路径！
        // 使用 Tcl Console 命令 `find_objects -r *u_PRF*data` 来查找
        if (uut.u_BACK_END.u_PRF.data[5] == 16'd30) begin
            $display("[PASS] Register check: PRF[5] (likely r5) holds the correct value (30).");
        end else begin
            $display("[FAIL] Register check: PRF[5] holds %d, expected 30.", uut.u_BACK_END.u_PRF.data[5]);
        end
        
        // 6. 结束仿真
        $display("---------------------------------------------------------");
        $display("[INFO] Test finished. Check logs and waveform for correctness.");
        $finish;
    end

endmodule