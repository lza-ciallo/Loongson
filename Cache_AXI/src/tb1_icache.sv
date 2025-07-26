`timescale 1ns/1ps

module tb_icache_test();

// 时钟和复位信号
reg clk;
reg rst;

// ICache测试信号
reg  [31:0] pc;
reg         Rena;
wire [31:0] inst[3:0];
wire        stall_if_request;
wire [2:0]  inst_size;
wire        Rdone;

// DCache测试信号 (暂时不用)
reg  [31:0] dcache_wdata_in  = 32'h0;
reg  [31:0] dcache_waddr_in  = 32'h0;
reg         dcache_wena_in   = 1'b0;
reg  [ 1:0] dcache_wsize_in  = 2'b0;
reg  [ 3:0] dcache_wmask_in  = 4'h0;
wire        dcache_wdone;
wire [31:0] dcache_rdata_out;
reg  [31:0] dcache_raddr_in  = 32'h0;
reg         dcache_rena_in   = 1'b0;
reg  [ 1:0] dcache_rsize_in  = 2'b0;
wire [ 3:0] dcache_rmask_out;
wire        dcache_rdone;
wire        stall_mem_request;

// 测试用变量
integer     cycle_count;
integer     test_case;
reg  [31:0] expected_inst;

// Unit Under Test
cache_test_top uut (
    .clk(clk),
    .rst(rst),
    // ICache测试接口
    .inst(inst),
    .stall_if_request(stall_if_request),
    .inst_size(inst_size),
    .pc(pc),
    .Rena(Rena),
    .Rdone(Rdone),
    // DCache测试接口
    .dcache_wdata_in(dcache_wdata_in),
    .dcache_waddr_in(dcache_waddr_in),
    .dcache_wena_in(dcache_wena_in),
    .dcache_wsize_in(dcache_wsize_in),
    .dcache_wmask_in(dcache_wmask_in),
    .dcache_wdone(dcache_wdone),
    .dcache_rdata_out(dcache_rdata_out),
    .dcache_raddr_in(dcache_raddr_in),
    .dcache_rena_in(dcache_rena_in),
    .dcache_rsize_in(dcache_rsize_in),
    .dcache_rmask_out(dcache_rmask_out),
    .dcache_rdone(dcache_rdone),
    .stall_mem_request(stall_mem_request)
);

// 100MHz
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz时钟
end

// test1.
initial begin
    $display("========================================");
    $display("ICache Test Bench Started");
    $display("========================================");
    
    // GLOBAL INIT
    global_init();
    
    // TEST1.
    // test_icache_hit();
    test0();
    


    $display("========================================");
    $display("All tests completed!");
    $display("========================================");
    
    #100;
    $finish;
end



// ========================================
// GLOBAL INIT
// ========================================
task global_init();
    begin
        $display("\n--- GLOBAL INIT ---");
        
        // rst
        rst = 0;
        pc = 32'h1c00_0000;
        Rena = 0;
        cycle_count = 0;
        test_case = 0;
        
        #20;
        rst = 1;
        #10;
        
        $display("System reset completed");
        
        // // init.icache
        // init_icache();
        
        $display("Global initialization completed\n");
    end
endtask


task test0();
    begin
        // pc = 32'h1c00_0004;
        pc = 32'h0000_0004;
        Rena = 1;
        # 10000;
        Rena = 0;
    end
endtask





















// // ICache Initialize
// task init_icache();
//     begin
//         $display("Pre-filling ICache...");
        
//         // 读取第一个缓存行 (地址0x00000000)
//         fetch_cacheline(32'h00000000);
        
//         // 读取第二个缓存行 (地址0x00000010) 
//         fetch_cacheline(32'h00000010);
        
//         $display("ICache pre-filled with 2 cache lines");
//     end
// endtask

// // 初始化缓存
// task fetch_cacheline(input [31:0] addr);
//     begin
//         pc = addr;
//         Rena = 1;
//         cycle_count = 0;
        
//         // 等待完成
//         wait(Rdone == 1);
//         cycle_count = cycle_count + 1;
        
//         @(posedge clk);
//         Rena = 0;
        
//         $display("  Fetched cache line at 0x%08h in %d cycles", addr, cycle_count);
//         #20; // 等待稳定
//     end
// endtask

// // ========================================
// // ICACHE TESTS
// // ========================================

// // Test.1: [Inst_req | hit]
// task test_icache_hit();
//     begin
//         $display("\n--- TEST.1: ICache Hit Test ---");
//         test_case = 1;
        
//         // init: 维护初始环境整洁
//         @(posedge clk);
//         pc = 32'h0;
//         Rena = 0;
//         #10;
        
//         // stim: 模拟CPU.IF1阶段对icache发出一条PC进行取指，确保hit
//         $display("Stimulating: Fetch instruction at PC=0x00000004 (should hit)");
        
//         pc = 32'h00000004; // 这个地址应该在已预填充的缓存行中
//         Rena = 1;
//         cycle_count = 0;
        
//         // exp.behave: PC要恰好命中icache中某个icache.line
//         // 监控缓存命中信号
//         // fork : fork_hit_check
//         //     begin
//         //         // 计数时钟周期直到Rdone
//         //         while(!Rdone) begin
//         //             @(posedge clk);
//         //             cycle_count = cycle_count + 1;
//         //         end
//         //     end
//         //     begin
//         //         // 检查是否为缓存命中 (应该很快完成，1-2个周期)
//         //         #50; // 等待足够时间
//         //         if(!Rdone) begin
//         //             $display("ERROR: Cache hit took too long (>5 cycles)");
//         //             $display("   This might indicate a cache miss instead of hit");
//         //         end
//         //     end
//         // join_any;
//         // disable fork_hit_check;
        
//         // exp.resp: 取出的指令符合预期，并记录所用时钟周期
//         if(Rdone) begin
//             expected_inst = 32'h9ABCDEF0; // 地址0x004对应的指令
            
//             $display("Response received after %d cycles:", cycle_count);
//             $display("  inst[0] = 0x%08h", inst[0]);
//             $display("  inst[1] = 0x%08h", inst[1]);  
//             $display("  inst[2] = 0x%08h", inst[2]);
//             $display("  inst[3] = 0x%08h", inst[3]);
//             $display("  inst_size = %d", inst_size);
            
//             // 检查指令是否正确
//             if(inst[1] == expected_inst) begin // PC=0x004对应inst[1]
//                 $display("PASS: Instruction matches expected value");
//                 $display("PASS: Cache hit completed in %d cycles", cycle_count);
//             end else begin
//                 $display("FAIL: Instruction mismatch");
//                 $display("   Expected: 0x%08h", expected_inst);
//                 $display("   Got:      0x%08h", inst[1]);
//             end
            
//             // 检查周期数 (缓存命中应该很快)
//             if(cycle_count <= 2) begin
//                 $display("PASS: Fast response indicates cache hit");
//             end else begin
//                 $display("WARNING: Slow response (%d cycles) might indicate cache miss", cycle_count);
//             end
            
//         end else begin
//             $display("FAIL: No response received");
//         end
        
//         // 清理
//         @(posedge clk);
//         Rena = 0;
//         #20;
        
//         $display("--- TEST.1 Completed ---\n");
//     end
// endtask

// // 监控信号变化
// always @(posedge clk) begin
//     if(Rena && test_case > 0) begin
//         $display("[Cycle %0t] PC=0x%08h, Rena=%b, Rdone=%b, stall=%b", $time, pc, Rena, Rdone, stall_if_request);
//     end
// end

endmodule