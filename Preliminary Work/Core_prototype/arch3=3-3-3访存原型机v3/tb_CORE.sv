`timescale 1ns / 1ps
`define CLK_PERIOD 10

module tb_CORE;

    reg             clk;
    reg             rst;
    reg [15 : 0]    ref_reg [7 : 0];
    reg [15 : 0]    ref_mem [3 : 0];

    CORE u_CORE (
        .clk        (clk),
        .rst        (rst)
    );

    initial begin
        clk = 0;
        rst = 1;
        forever # (`CLK_PERIOD/2) begin
            clk <= ~clk;
        end
    end

    assign  stop = u_CORE.flush;

    integer wrong_num = 0;

    initial begin
        @(negedge clk);
        // $readmemh("C:/Users/linzi/Desktop/NSCSCC2025/ELEC_core_v3/inst_init/data_hex_original.txt", ref_reg);
        $readmemh("C:/Users/linzi/Desktop/NSCSCC2025/ELEC_core_v3/inst_init/data_hex_memory.txt", ref_reg);
        $readmemh("C:/Users/linzi/Desktop/NSCSCC2025/ELEC_core_v3/inst_init/mem_hex_memory.txt", ref_mem);
        @(negedge clk) rst = 0;
        @(negedge clk) rst = 1;
        while(stop != 1) begin
            @(negedge clk);
        end
        $display("stop at time: %d ns", $time);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        for (integer i = 0; i < 8; i = i + 1) begin
            if (u_CORE.u_BACK_END.u_PRF.data[u_CORE.u_FRONT_END.u_SRAT.list[i].P_list] !== ref_reg[i]) begin
                $display("reg wrong at %d, output %d, reference %d", i, u_CORE.u_BACK_END.u_PRF.data[u_CORE.u_FRONT_END.u_SRAT.list[i].P_list], ref_reg[i]);
                wrong_num = wrong_num + 1;
            end
        end
        for (integer i = 0; i < 4; i = i + 1) begin
            if (u_CORE.u_BACK_END.u_DATA_MEM.mem_data[i] !== ref_mem[i]) begin
                $display("mem wrong at %d, output %d, reference %d", i, u_CORE.u_BACK_END.u_DATA_MEM.mem_data[i], ref_mem[i]);
                wrong_num = wrong_num + 1;
            end
        end
        $display("wrong num: %d",wrong_num);
        @(negedge clk)
        $finish(0);
    end

endmodule