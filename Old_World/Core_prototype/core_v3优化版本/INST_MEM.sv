module INST_MEM (
    input   [ 7 : 0]    pc,
    output  [12 : 0]    inst    [2 : 0]
);

    reg     [12 : 0]    inst_mem    [255 : 0];

    integer i;

    initial begin
        // $readmemb("C:/Users/linzi/Desktop/NSCSCC2025/ELEC_core_v3/inst_init/inst_bin_original.txt", inst_mem);
        // for (i = 26; i < 256; i = i + 1) begin
        //     inst_mem[i] <= '0;
        // end
        $readmemb("C:/Users/linzi/Desktop/NSCSCC2025/ELEC_core_v3/inst_init/inst_bin_memory.txt", inst_mem);
        for (i = 44; i < 256; i = i + 1) begin
            inst_mem[i] <= '0;
        end
    end

    assign  inst[0] =   inst_mem[pc];
    assign  inst[1] =   inst_mem[pc + 1];
    assign  inst[2] =   inst_mem[pc + 2];

endmodule