`timescale 1ns / 1ps
//说明：这个testbench实际上我感觉只能验证一下逻辑在基本运转，由于冷启动比较明显，tb样例过短并没有展示出
//GHR带来了什么好处，不过逻辑应该没有问题
module tb_Gshare_predictor;

    localparam K         = 13; 
    localparam GHR_WIDTH = K;   
    localparam CLK_PERIOD = 10; 

    reg clk;
    reg rst;
    reg [31:0] pc_in;
    reg update_en;
    reg [31:0] update_pc;
    reg [GHR_WIDTH-1:0] update_ghr_val;
    reg actual_taken;
    wire prediction;

    reg [GHR_WIDTH-1:0] tb_ghr; 

    Gshare_predictor #(.K(K), .GHR_WIDTH(GHR_WIDTH)) uut (
        .clk(clk),
        .rst(rst),
        .pc_in(pc_in),
        .update_en(update_en),
        .update_pc(update_pc),
        .update_ghr_val(update_ghr_val), 
        .actual_taken(actual_taken),
        .prediction(prediction)
    );


    always #(CLK_PERIOD / 2) clk = ~clk;

    task apply_branch;
        input [31:0] branch_pc;
        input        is_taken;
    begin

        pc_in = branch_pc;

        update_ghr_val = tb_ghr; 
        
        // 打印预测前的状态
        $display("[%0t] PC_in: %h, GHR (pre-predict): %h, Predicted: %b",
                 $time, pc_in, tb_ghr, prediction);
        #(CLK_PERIOD * 2); 
        
        update_en    = 1'b1;

        update_pc    = branch_pc;
        actual_taken = is_taken;
        
        $display("[%0t] Update_PC: %h, Actual_Taken: %b, GHR (used for update): %h", 
                 $time, update_pc, actual_taken, update_ghr_val);

        #CLK_PERIOD;
        

        update_en = 1'b0;

        tb_ghr = {tb_ghr[GHR_WIDTH-2:0], actual_taken};
        $display("[%0t] TB_GHR updated to: %h", $time, tb_ghr);

    end
    endtask


    initial begin
        $display("=======================================");
        $display("         Branch Predictor Test         ");
        $display("     (With GHR Hashing Support)        ");
        $display("=======================================");
        
        clk = 0;
        rst = 1;
        pc_in = 0;
        update_en = 0;
        update_pc = 0;
        update_ghr_val = 0; 
        actual_taken = 0;
        tb_ghr = 0;         
        
        # (CLK_PERIOD * 2);
        rst = 0;
        $display("[%0t] Reset released.", $time);
        
        $monitor("[%0t] Current Prediction: %b, PHT_Index (predicted): %h, PHT_Entry: %b",
                 $time, prediction, (pc_in[K+1:2] ^ tb_ghr), uut.pht[(pc_in[K+1:2] ^ tb_ghr)]);


        $display("\n--- Test Case 1: Always Taken Branch (PC: 0x...100) ---");
        apply_branch(32'h00000100, 1); // 首次：GHR为00..0，可能预测错误
        apply_branch(32'h00000100, 1); // 再次：GHR已更新，可能会改善预测
        apply_branch(32'h00000100, 1); 
        apply_branch(32'h00000100, 1); 
        
        #(CLK_PERIOD * 5);

        $display("\n--- Test Case 2: Always Not-Taken Branch (PC: 0x...200) ---");
        apply_branch(32'h00000200, 0); 
        apply_branch(32'h00000200, 0); 
        
        #(CLK_PERIOD * 5);

        // 测试场景3: 模拟一个循环 (例如 for i=0; i<3; i++)
        $display("\n--- Test Case 3: Loop Branch (PC: 0x...304) ---");
        apply_branch(32'h00000304, 1); // 循环第1次，跳转
        apply_branch(32'h00000304, 1); // 循环第2次，跳转
        apply_branch(32'h00000304, 0); // 循环结束，不跳转
        
        apply_branch(32'h00000304, 1); // 新循环第1次，跳转
        apply_branch(32'h00000304, 1); // 新循环第2次，跳转
        apply_branch(32'h00000304, 0); // 新循环结束，不跳转
        
        #(CLK_PERIOD * 5);

        $display("\n--- Test Finished ---");
        $finish;
    end

endmodule