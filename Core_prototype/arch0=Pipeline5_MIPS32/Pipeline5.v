module Pipeline5 (
    input           clk,
    input           rst,
    output  [7 : 0] leds,
    output  [3 : 0] enable
);

    // localparam  BW_MUL  =   160;
    localparam  BW_MUL  =   96;

    wire    [31 : 0]    BranchAddr;
    wire    [31 : 0]    JumpAddr;


    localparam  BW_IF   =   32 * 2;
    wire    [31 : 0]        pc_IF, pc_IF_reg;
    wire    [31 : 0]        inst_IF, inst_IF_reg;
    wire    [BW_IF - 1 : 0] bunch_IF, bunch_IF_reg;
    assign  bunch_IF = {pc_IF, inst_IF};
    assign  {pc_IF_reg, inst_IF_reg} = bunch_IF_reg;


    localparam  BW_ID   =   5 * 4 + 32 * 5 + 1 * 3 + 2 + 4 + 3;
    wire    [4 : 0]         rs_ID, rs_ID_reg;
    wire    [4 : 0]         rt_ID, rt_ID_reg;
    wire    [4 : 0]         rw_ID, rw_ID_reg;
    wire    [4 : 0]         shamt_ID, shamt_ID_reg;
    wire    [31 : 0]        pc_ID, pc_ID_reg;
    wire    [31 : 0]        ExtImm32_ID, ExtImm32_ID_reg;
    wire    [31 : 0]        LuiImm32_ID, LuiImm32_ID_reg;
    wire    [31 : 0]        busA_ID, busA_ID_reg;
    wire    [31 : 0]        busB_ID, busB_ID_reg;
    wire                    RegWr_ID, RegWr_ID_reg;
    wire                    MemWr_ID, MemWr_ID_reg;
    wire    [1 : 0]         MemtoReg_ID, MemtoReg_ID_reg;
    wire                    ALUSrc_ID, ALUSrc_ID_reg;
    wire    [3 : 0]         ALUConf_ID, ALUConf_ID_reg;
    wire    [2 : 0]         BranchConf_ID, BranchConf_ID_reg;
    assign  pc_ID = pc_IF_reg;
    wire    [BW_ID - 1 : 0] bunch_ID, bunch_ID_reg;
    assign  bunch_ID = {rs_ID, rt_ID,  rw_ID, shamt_ID, pc_ID, ExtImm32_ID, LuiImm32_ID, busA_ID, busB_ID,
                    RegWr_ID, MemWr_ID, MemtoReg_ID, ALUSrc_ID, ALUConf_ID, BranchConf_ID};
    assign  {rs_ID_reg, rt_ID_reg, rw_ID_reg, shamt_ID_reg, pc_ID_reg, ExtImm32_ID_reg, LuiImm32_ID_reg, busA_ID_reg, busB_ID_reg,
                    RegWr_ID_reg, MemWr_ID_reg, MemtoReg_ID_reg, ALUSrc_ID_reg, ALUConf_ID_reg, BranchConf_ID_reg} = bunch_ID_reg;


    wire    [31 : 0]        busA_in;
    wire    [31 : 0]        busB_in;
    wire    [1 : 0]         rsSrc;
    wire    [1 : 0]         rtSrc;


    localparam  BW_EX   =   32 * 4 + BW_MUL + 2 + 1 * 3 + 2 + 5 * 2;
    wire    [31 : 0]        Result_EX, Result_EX_reg;
    wire    [31 : 0]        pc_EX, pc_EX_reg;
    wire    [31 : 0]        LuiImm32_EX, LuiImm32_EX_reg;
    wire    [31 : 0]        busB_EX, busB_EX_reg;
    wire    [BW_MUL-1:0]    half_Result_EX, half_Result_EX_reg;
    wire    [1 : 0]         MemtoReg_EX, MemtoReg_EX_reg;
    wire                    RegWr_EX, RegWr_EX_reg;
    wire                    MemWr_EX, MemWr_EX_reg;
    wire                    Mul_EX, Mul_EX_reg;
    wire    [4 : 0]         rt_EX, rt_EX_reg;
    wire    [4 : 0]         rw_EX, rw_EX_reg;
    assign  {pc_EX, LuiImm32_EX, busB_EX, MemtoReg_EX, RegWr_EX, MemWr_EX, rt_EX, rw_EX} =
            {pc_ID_reg, LuiImm32_ID_reg, busB_in, MemtoReg_ID_reg, RegWr_ID_reg, MemWr_ID_reg, rt_ID_reg, rw_ID_reg};
    wire    [BW_EX - 1 : 0] bunch_EX, bunch_EX_reg;
    assign  bunch_EX = {Result_EX, pc_EX, LuiImm32_EX, busB_EX, half_Result_EX,
            MemtoReg_EX, RegWr_EX, MemWr_EX, Mul_EX, rt_EX, rw_EX};
    assign  {Result_EX_reg, pc_EX_reg, LuiImm32_EX_reg, busB_EX_reg, half_Result_EX_reg,
            MemtoReg_EX_reg, RegWr_EX_reg, MemWr_EX_reg, Mul_EX_reg, rt_EX_reg, rw_EX_reg} = bunch_EX_reg;


    localparam  BW_MEM  =   32 + 1 + 5 * 2;
    wire    [31 : 0]        busW_MEM, busW_WB;
    wire                    RegWr_MEM, RegWr_WB;
    wire    [4 : 0]         rt_MEM, rt_WB;
    wire    [4 : 0]         rw_MEM, rw_WB; 
    assign  {RegWr_MEM, rt_MEM, rw_MEM} = {RegWr_EX_reg, rt_EX_reg, rw_EX_reg};
    wire    [BW_MEM - 1 : 0]    bunch_MEM, bunch_WB;
    assign  bunch_MEM = {busW_MEM, RegWr_MEM, rt_MEM, rw_MEM};
    assign  {busW_WB, RegWr_WB, rt_WB, rw_WB} = bunch_WB;


    assign  busA_in = (rsSrc == 2)? busW_WB : (rsSrc == 1)? Result_EX_reg : busA_ID_reg;
    assign  busB_in = (rtSrc == 2)? busW_WB : (rtSrc == 1)? Result_EX_reg : busB_ID_reg;


    wire    [31 : 0]        data_in;
    wire                    dataSrc;
    assign  data_in = (dataSrc == 1)? busW_WB : busB_EX_reg;


    assign  nop = 0;


    IF u_IF (
        .clk(clk),
        .rst(rst),
        .stall(stall_PC),
        .Branch(Branch),
        .Jump(Jump),
        .BranchAddr(BranchAddr),
        .JumpAddr(JumpAddr),
        .pc(pc_IF),
        .inst(inst_IF)
    );

    REGISTER #(
        .BW(BW_IF)
    ) u_REG_IF_ID (
        .clk(clk),
        .rst(rst),
        .stall(stall_IF_ID),
        .flush(flush_IF_ID),
        .data_in(bunch_IF),
        .data_out(bunch_IF_reg)
    );

    ID u_ID (
        .clk(clk),
        .rst(rst),

        .inst(inst_IF_reg),
        .pc(pc_IF_reg),
        .rs(rs_ID),
        .rt(rt_ID),
        .rw(rw_ID),
        .shamt(shamt_ID),
        .ExtImm32(ExtImm32_ID),
        .LuiImm32(LuiImm32_ID),
        .JumpAddr(JumpAddr),
        .busA(busA_ID),
        .busB(busB_ID),

        .RegWr(RegWr_ID),
        .MemWr(MemWr_ID),
        .MemtoReg(MemtoReg_ID),
        .ALUSrc(ALUSrc_ID),
        .ALUConf(ALUConf_ID),
        .BranchConf(BranchConf_ID),
        .Jump(Jump),

        .RegWr_in(RegWr_WB),
        .busW_in(busW_WB),
        .rw_in(rw_WB)
    );

    REGISTER #(
        .BW(BW_ID)
    ) u_REG_ID_EX (
        .clk(clk),
        .rst(rst),
        .stall(stall_ID_EX),
        .flush(flush_ID_EX),
        .data_in(bunch_ID),
        .data_out(bunch_ID_reg)
    );

    EX #(
        .BW_MUL(BW_MUL)
    ) u_EX (
        .busA(busA_in),
        .busB(busB_in),
        .ExtImm32(ExtImm32_ID_reg),
        .pc(pc_ID_reg),
        .ALUConf(ALUConf_ID_reg),
        .BranchConf(BranchConf_ID_reg),
        .shamt(shamt_ID_reg),
        .Result(Result_EX),
        .BranchAddr(BranchAddr),
        .ALUSrc(ALUSrc_ID_reg),
        .Branch(Branch),
        .USE_RT_EX(USE_RT_EX),
        .Mul(Mul_EX),
        .half_Result(half_Result_EX)
    );

    REGISTER #(
        .BW(BW_EX)
    ) u_REG_EX_MEM (
        .clk(clk),
        .rst(rst),
        .stall(nop),
        .flush(flush_EX_MEM),
        .data_in(bunch_EX),
        .data_out(bunch_EX_reg)
    );

    MEM #(
        .BW_MUL(BW_MUL)
    ) u_MEM (
        .clk(clk),
        .rst(rst),
        .MemWr(MemWr_EX_reg),
        .MemtoReg(MemtoReg_EX_reg),
        .Result(Result_EX_reg),
        .busB(data_in),
        .LuiImm32(LuiImm32_EX_reg),
        .pc(pc_EX_reg),
        .leds(leds),
        .enable(enable),
        .busW(busW_MEM),
        .half_Result(half_Result_EX_reg),
        .Mul(Mul_EX_reg)
    );

    REGISTER #(
        .BW(BW_MEM)
    ) u_REG_MEM_WB (
        .clk(clk),
        .rst(rst),
        .stall(nop),
        .flush(nop),
        .data_in(bunch_MEM),
        .data_out(bunch_WB)
    );

    HAZARD u_HAZARD (
        .rs_EX(rs_ID_reg),
        .rt_EX(rt_EX),
        .rt_MEM(rt_MEM),
        .rw_MEM(rw_MEM),
        .rw_WB(rw_WB),
        
        .RegWr_MEM(RegWr_MEM),
        .MemtoReg_MEM(MemtoReg_EX_reg),
        .RegWr_WB(RegWr_WB),

        .MemWr_EX(MemWr_EX),
        .MemWr_MEM(MemWr_EX_reg),
        .Jump(Jump),
        .Branch(Branch),
        .USE_RT_EX(USE_RT_EX),
        .Mul_MEM(Mul_EX_reg),

        .rsSrc(rsSrc),
        .rtSrc(rtSrc),
        .dataSrc(dataSrc),
        .stall_PC(stall_PC),
        .stall_IF_ID(stall_IF_ID),
        .flush_IF_ID(flush_IF_ID),
        .stall_ID_EX(stall_ID_EX),
        .flush_ID_EX(flush_ID_EX),
        .flush_EX_MEM(flush_EX_MEM)
    );

endmodule