`timescale 1ns / 1ps

module My_CPU_tb;

    // --- 参数定义 ---
    parameter CLK_PERIOD = 10; // 10ns 时钟周期 (100MHz)

    // --- 信号声明 ---
    reg clk;
    reg rst;

    // --- 实例化待测试的CPU ---
    My_CPU uut (
        .clk(clk),
        .rst(rst)
    );

    // --- 时钟生成 ---
    initial begin
        clk = 0;
        forever # (CLK_PERIOD / 2) clk = ~clk;
    end

    // --- 测试序列 ---
    initial begin
        // 1. 打印开始信息
        $display("-------------------------------------------------");
        $display("T=%0t: [INFO] Testbench Started.", $time);
        
        // 2. 施加复位
        rst = 1'b1;
        repeat(5) @(posedge clk);
        $display("T=%0t: [INFO] Applying Reset.", $time);
        
        // 3. 释放复位，CPU开始运行
        rst = 1'b0;
        @(posedge clk);
        $display("T=%0t: [INFO] Reset Released. CPU starts execution.", $time);
        
        // 4. 让仿真运行足够长的时间来完成程序
        // 我们的程序很短，但因为有Cache Miss和流水线，给它多一点时间
        repeat(100) @(posedge clk);
        
        // 5. 结束仿真
        $display("T=%0t: [INFO] Test finished.", $time);
        $display("-------------------------------------------------");
        $finish;
    end

endmodule