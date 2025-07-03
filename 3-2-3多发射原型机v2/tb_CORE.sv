`timescale 1ns / 1ps
`define CLK_PERIOD 10

module tb_CORE;

    reg             clk;
    reg             rst;
    reg [15 : 0]    ref_reg [7 : 0];

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
        $readmemh("C:/Users/linzi/Desktop/thisSemester/OutofOrderProcessors/data/data_bin_x2.txt", ref_reg);
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
            if (u_CORE.u_BACK_END.u_PRF.data[u_CORE.u_FRONT_END.u_SRAT.P_list[i]] !== ref_reg[i]) begin
                $display("wrong at %d, output %d, reference %d", i, u_CORE.u_BACK_END.u_PRF.data[u_CORE.u_FRONT_END.u_SRAT.P_list[i]], ref_reg[i]);
                wrong_num = wrong_num + 1;
            end
        end
        $display("wrong num: %d",wrong_num);
        @(negedge clk)
        $finish(0);
    end

endmodule