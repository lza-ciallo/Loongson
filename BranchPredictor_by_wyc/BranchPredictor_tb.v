
`timescale 1ns / 1ps

module tb_branch_predictor;

    // 参数定义
    localparam K = 13; 
    localparam CLK_PERIOD = 10; 


    reg clk;
    reg rst;
    reg [31:0] pc_in;
    reg update_en;
    reg [31:0] update_pc;
    reg actual_taken;
    wire prediction;

    branch_predictor #(.K(K)) uut (
        .clk(clk),
        .rst(rst),
        .pc_in(pc_in),
        .update_en(update_en),
        .update_pc(update_pc),
        .actual_taken(actual_taken),
        .prediction(prediction)
    );

    always #(CLK_PERIOD / 2) clk = ~clk;

    task apply_branch;
        input [31:0] branch_pc;
        input        is_taken;
    begin
        pc_in = branch_pc;
        
        // 延迟一段时间，模拟指令通过流水线
        #(CLK_PERIOD * 2); 
        
        update_en    = 1'b1;
        update_pc    = branch_pc;
        actual_taken = is_taken;
        
        #CLK_PERIOD;
        
        update_en = 1'b0;
    end
    endtask


    initial begin
        $display("=======================================");
        $display("         Branch Predictor Test         ");
        $display("=======================================");
        clk = 0;
        rst = 1;
        pc_in = 0;
        update_en = 0;
        update_pc = 0;
        actual_taken = 0;
        
        # (CLK_PERIOD * 2);
        rst = 0;
        $display("[%0t] Reset released.", $time);
        
        $monitor("[%0t] PC: %h, Actual: %b, Prediction: %b, PHT[%h]: %b",
                  $time, update_pc, actual_taken, prediction, update_pc[K+1:2], uut.pht[update_pc[K+1:2]]);


        $display("\n--- Test Case 1: Always Taken Branch (PC: 0x...100) ---");
        apply_branch(32'h00000100, 1); // 第一次：预测错误 
        apply_branch(32'h00000100, 1); // 第二次：预测正确 
        apply_branch(32'h00000100, 1); // 第三次：预测正确 
        apply_branch(32'h00000100, 1); // 第四次：预测正确 
        
        #(CLK_PERIOD * 5);

        $display("\n--- Test Case 2: Always Not-Taken Branch (PC: 0x...200) ---");
        apply_branch(32'h00000200, 0); // 第一次：预测正确 
        apply_branch(32'h00000200, 0); // 第二次：预测正确 
        
        #(CLK_PERIOD * 5);

        // 4. 测试场景3: 模拟一个循环 (例如 for i=0; i<3; i++)
        $display("\n--- Test Case 3: Loop Branch (PC: 0x...304) ---");
        apply_branch(32'h00000304, 1); // 循环第1次，跳转 (预测错误)
        apply_branch(32'h00000304, 1); // 循环第2次，跳转 (预测错误)
        apply_branch(32'h00000304, 0); // 循环结束，不跳转 (预测错误)
        apply_branch(32'h00000304, 1); // 下一次进入循环，跳转 (预测正确)
        apply_branch(32'h00000304, 1); // 循环中，跳转 (预测正确)
        apply_branch(32'h00000304, 0); // 再次结束循环，不跳转 (预测错误)
        
        #(CLK_PERIOD * 5);

        $display("\n--- Test Finished ---");
        $finish;
    end

endmodule