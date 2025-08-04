module CPUCONF(
    input   [31: 0]     cpuconf_id,
    output  [31: 0]     cpuconf_value
); 

    wire [31: 0] cpuconf_lut [31: 0];
    // PRID 
    //  0
    assign cpuconf_lut[0] = 32'h0;

    // ARCH PGMMU IOCSR  PALEN      VALEN    UAL RI EP RPLV HP CRC MSG_INT 
    //  00    0     1   00011111  00011111    0   0  0   0  0   0     0
    // assign cpuconf_lut[1] = 32'b0000_0000_0000_0001_1111_0001_1111_1000;
    assign cpuconf_lut[1] = 32'h1f1f4;
    // ABOUT FLOAT
    assign cpuconf_lut[2] = 32'h0;
    assign cpuconf_lut[16] = 32'b0000_0000_0000_0000_0000_0000_0000_0101;
    // assign cpuconf_lut[17] = 32'b0000_0100_0000_1000_0000_0000_0000_0010;
    assign cpuconf_lut[17] = 32'h04080001;
    // assign cpuconf_lut[18] = 32'b0000_0100_0000_1000_0000_0000_0000_0010;
    assign cpuconf_lut[18] = 32'h04080001; 
    assign cpuconf_lut[19] = 32'h0;
    assign cpuconf_lut[20] = 32'h0;

    assign cpuconf_value = cpuconf_lut[cpuconf_id];

endmodule