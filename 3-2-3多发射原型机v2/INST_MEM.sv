module INST_MEM (
    input               rst,
    input   [7 : 0]     pc,
    output  [9 : 0]     inst_x,
    output  [9 : 0]     inst_y,
    output  [9 : 0]     inst_z
);

    reg     [9 : 0]     inst_mem [255 : 0];

    integer i;

    always @(negedge rst) begin
        for (i = 26; i < 256; i = i + 1) begin
            inst_mem[i] <= '0;
        end
        $readmemb("C:/Users/linzi/Desktop/thisSemester/OutofOrderProcessors/data/inst_bin_x2.txt", inst_mem);
    end

    assign  inst_x = inst_mem[pc];
    assign  inst_y = inst_mem[pc + 1];
    assign  inst_z = inst_mem[pc + 2];

endmodule