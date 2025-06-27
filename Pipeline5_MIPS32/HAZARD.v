module HAZARD (
    input   [4 : 0]     rs_EX,
    input   [4 : 0]     rt_EX,
    input   [4 : 0]     rt_MEM,
    input   [4 : 0]     rw_MEM,
    input   [4 : 0]     rw_WB,
    
    input               RegWr_MEM,
    input   [1 : 0]     MemtoReg_MEM,
    input               RegWr_WB,

    input               MemWr_EX,
    input               MemWr_MEM,
    input               Jump,
    input               Branch,
    input               USE_RT_EX,
    input               Mul_MEM,

    output  reg [1 : 0] rsSrc,
    output  reg [1 : 0] rtSrc,
    output  reg         dataSrc,
    output  reg         stall_PC,
    output  reg         stall_IF_ID,
    output  reg         flush_IF_ID,
    output  reg         stall_ID_EX,
    output  reg         flush_ID_EX,
    output  reg         flush_EX_MEM
);

    wire    USE_RT_EX_real;
    assign  USE_RT_EX_real = USE_RT_EX | MemWr_EX;

    wire    LW_MUL;
    assign  LW_MUL = (RegWr_MEM == 1 && (MemtoReg_MEM == 1 || Mul_MEM == 1))? 1 : 0;

    reg     Load_Use_Stall;

    always @(*) begin
        if (rs_EX == rw_MEM && LW_MUL)                                      Load_Use_Stall = 1;
        else if (rt_EX == rw_MEM && LW_MUL && USE_RT_EX_real)               Load_Use_Stall = 1;
        else                                                                Load_Use_Stall = 0;

        if (rs_EX == rw_MEM && RegWr_MEM == 1 && MemtoReg_MEM != 1)         rsSrc = 1;
        else if (rs_EX == rw_WB && RegWr_WB == 1)                           rsSrc = 2;
        else                                                                rsSrc = 0;

        if (USE_RT_EX_real) begin
            if (rt_EX == rw_MEM && RegWr_MEM == 1 && MemtoReg_MEM != 1)     rtSrc = 1;
            else if (rt_EX == rw_WB && RegWr_WB == 1)                       rtSrc = 2;
            else                                                            rtSrc = 0;
        end else                                                            rtSrc = 0;

        if (MemWr_MEM == 1 && rt_MEM == rw_WB && RegWr_WB == 1)             dataSrc = 1;
        else                                                                dataSrc = 0;
    end

    always @(*) begin
        if (Load_Use_Stall) begin
            {stall_PC, stall_IF_ID, stall_ID_EX} = 3'b111;
            {flush_IF_ID, flush_ID_EX, flush_EX_MEM} = 3'b001;
        end
        else if (Branch) begin
            {stall_PC, stall_IF_ID, stall_ID_EX} = 3'b000;
            {flush_IF_ID, flush_ID_EX, flush_EX_MEM} = 3'b110;
        end
        else if (Jump) begin
            {stall_PC, stall_IF_ID, stall_ID_EX} = 3'b000;
            {flush_IF_ID, flush_ID_EX, flush_EX_MEM} = 3'b100;
        end
        else begin
            {stall_PC, stall_IF_ID, stall_ID_EX} = 3'b000;
            {flush_IF_ID, flush_ID_EX, flush_EX_MEM} = 3'b000;
        end
    end

endmodule