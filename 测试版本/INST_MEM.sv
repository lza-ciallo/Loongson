module INST_MEM (
    input               rst,
    input   [7 : 0]     pc,
    output  [9 : 0]     inst
);

    reg     [9 : 0]     inst_mem [255 : 0];

    always @(negedge rst) begin
        $readmemb("C:/Users/linzi/Desktop/thisSemester/OutofOrderProcessors/data/inst_bin.txt", inst_mem);
    end

    assign inst = inst_mem[pc];
    
endmodule