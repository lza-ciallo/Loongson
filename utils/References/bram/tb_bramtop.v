`timescale 1ns / 1ps

module top_module_tb;

    // 参数定义
    parameter CLK_PERIOD = 10; // 时钟周期为 10ns (100MHz)

    // 信号声明
    reg clk;

    // 实例化待测试模块 (DUT)
    Bramtop dut (
        .clk(clk)
    );

    // 1. 时钟生成
    initial begin
        clk = 0;
        forever # (CLK_PERIOD / 2) clk = ~clk;
    end

    // 2. 测试激励和验证
    initial begin
        // --- 初始化 ---
        $display("--------------------------------------------------");
        $display("T=%0t: [INFO] Testbench Started.", $time);
        
        // 初始化 BRAM 控制信号 (通过层级引用)
        dut.ena_a   = 0;
        dut.wea_a   = 0;
        dut.addra_a = 0;
        dut.dina_a  = 0;
        
        dut.enb_b   = 0;
        dut.web_b   = 0;
        dut.addrb_b = 0;
        dut.dinb_b  = 0;
        
        // 等待几个周期让系统稳定
        repeat(2) @(posedge clk);
        
        // --- 测试场景 1: 通过 Port A 写入数据 ---
        $display("T=%0t: [INFO] === Starting Write Sequence (Port A) ===", $time);

        // 写操作 1: 地址 0x10, 数据 0xAA
        @(posedge clk);
        dut.ena_a   = 1;
        dut.wea_a   = 1; // 写使能
        dut.addra_a = 10'h010;
        dut.dina_a  = 8'hAA;
        $display("T=%0t: [WRITE] Writing 0x%h to address 0x%h", $time, dut.dina_a, dut.addra_a);

        // 写操作 2: 地址 0x25, 数据 0xBB
        @(posedge clk);
        dut.addra_a = 10'h025;
        dut.dina_a  = 8'hBB;
        $display("T=%0t: [WRITE] Writing 0x%h to address 0x%h", $time, dut.dina_a, dut.addra_a);
        
        // 写操作 3: 地址 0xFF, 数据 0xCC
        @(posedge clk);
        dut.addra_a = 10'h0FF;
        dut.dina_a  = 8'hCC;
        $display("T=%0t: [WRITE] Writing 0x%h to address 0x%h", $time, dut.dina_a, dut.addra_a);

        // 结束写操作
        @(posedge clk);
        dut.ena_a = 0;
        dut.wea_a = 0;
        $display("T=%0t: [INFO] Write sequence finished.", $time);
        
        // 等待一下，让读写操作分开
        repeat(3) @(posedge clk);
        
        // --- 测试场景 2: 通过 Port B 读出数据并验证 ---
        $display("T=%0t: [INFO] === Starting Read Sequence (Port B) ===", $time);

        // 读操作 1: 读取地址 0x10
        @(posedge clk);
        dut.enb_b = 1;
        dut.web_b = 0; // 确保是读操作
        dut.addrb_b = 10'h010;
        $display("T=%0t: [READ] Reading from address 0x%h. Data will be valid on the next clock edge.", $time, dut.addrb_b);

        // **关键点: 等待一个时钟周期后，数据才会出现在 doutb_b**
        @(posedge clk);
        $display("T=%0t: [VERIFY] Address 0x%h, Expected: 0xAA, Got: 0x%h", $time, dut.addrb_b, dut.doutb_b);
        if (dut.doutb_b === 8'hAA) begin
            $display("T=%0t: [PASS] Data matches!", $time);
        end else begin
            $error("T=%0t: [FAIL] Data mismatch!", $time);
        end

        // 读操作 2: 读取地址 0x25
        @(posedge clk);
        dut.addrb_b = 10'h025;
        $display("T=%0t: [READ] Reading from address 0x%h. Data will be valid on the next clock edge.", $time, dut.addrb_b);

        @(posedge clk);
        $display("T=%0t: [VERIFY] Address 0x%h, Expected: 0xBB, Got: 0x%h", $time, dut.addrb_b, dut.doutb_b);
        if (dut.doutb_b === 8'hBB) begin
            $display("T=%0t: [PASS] Data matches!", $time);
        end else begin
            $error("T=%0t: [FAIL] Data mismatch!", $time);
        end
        
        // 读操作 3: 读取地址 0xFF
        @(posedge clk);
        dut.addrb_b = 10'h0FF;
        $display("T=%0t: [READ] Reading from address 0x%h. Data will be valid on the next clock edge.", $time, dut.addrb_b);

        @(posedge clk);
        $display("T=%0t: [VERIFY] Address 0x%h, Expected: 0xCC, Got: 0x%h", $time, dut.addrb_b, dut.doutb_b);
        if (dut.doutb_b === 8'hCC) begin
            $display("T=%0t: [PASS] Data matches!", $time);
        end else begin
            $error("T=%0t: [FAIL] Data mismatch!", $time);
        end
        
        // 结束读操作
        @(posedge clk);
        dut.enb_b = 0;
        $display("T=%0t: [INFO] Read sequence finished.", $time);

        // --- 结束仿真 ---
        repeat(5) @(posedge clk);
        $display("T=%0t: [INFO] Testbench Finished.", $time);
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
