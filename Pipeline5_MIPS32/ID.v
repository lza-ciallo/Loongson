module DECODER (
    input   [31 : 0]    inst,
    input   [31 : 0]    pc,
    output  [4 : 0]     rs,
    output  [4 : 0]     rt,
    output  [4 : 0]     rd,
    output  [4 : 0]     shamt,
    output  [15 : 0]    imm16,
    output  [31 : 0]    JAddr,

    output  reg             RegWr,
    output  reg             MemWr,
    output  reg     [1 : 0] RegDst,
    output  reg     [1 : 0] MemtoReg,
    output  reg             ALUSrc,
    output  reg             ExtOp,
    output  reg     [3 : 0] ALUConf,
    output  reg     [2 : 0] BranchConf,
    output  reg             Jump,
    output  reg             Jr
);

    wire    [5 : 0]     opcode;
    wire    [5 : 0]     funct;
    wire    [25 : 0]    imm26;
    wire    [31 : 0]    pcAdd4;

    assign  {opcode, rs, rt, rd, shamt, funct} = inst;
    assign  imm16 = inst[15 : 0];
    assign  imm26 = inst[25 : 0];
    assign  pcAdd4 = pc + 4;
    assign  JAddr = {pcAdd4[31 : 28], imm26, 2'b00};

    localparam  ADD = 0,    ADDU = 1,   SUB = 2,    SUBU = 3,   ADDI = 4,   ADDIU = 5;
    localparam  AND = 6,    OR = 7,     XOR = 8,    NOR = 9,    ANDI = 10,  SLL = 11,   SRL = 12,   SRA = 13,   SLT = 14,   SLTU = 15,  SLTIU = 16;
    localparam  BEQ = 17,   BNE = 18,   BLEZ = 19,  BGTZ = 20,  BLTZ = 21,  J = 22,     JAL = 23,   JR = 24,    JALR = 25;
    localparam  LW = 26,    SW = 27,    LUI = 28,   MUL = 29;

    reg     [4 : 0]     state;

    always @(*) begin
        // casez ({opcode, funct})
        //     {6'h00, 6'h20}: state = ADD;
        //     {6'h00, 6'h21}: state = ADDU;
        //     {6'h00, 6'h22}: state = SUB;
        //     {6'h00, 6'h23}: state = SUBU;
        //     {6'h08, 6'h??}: state = ADDI;
        //     {6'h09, 6'h??}: state = ADDIU;
        //     {6'h00, 6'h24}: state = AND;
        //     {6'h00, 6'h25}: state = OR;
        //     {6'h00, 6'h26}: state = XOR;
        //     {6'h00, 6'h27}: state = NOR;
        //     {6'h0c, 6'h??}: state = ANDI;
        //     {6'h00, 6'h00}: state = SLL;
        //     {6'h00, 6'h02}: state = SRL;
        //     {6'h00, 6'h03}: state = SRA;
        //     {6'h00, 6'h2a}: state = SLT;
        //     {6'h00, 6'h2b}: state = SLTU;
        //     {6'h0b, 6'h??}: state = SLTIU;
        //     {6'h04, 6'h??}: state = BEQ;
        //     {6'h05, 6'h??}: state = BNE;
        //     {6'h06, 6'h??}: state = BLEZ;
        //     {6'h07, 6'h??}: state = BGTZ;
        //     {6'h01, 6'h??}: state = BLTZ;
        //     {6'h02, 6'h??}: state = J;
        //     {6'h03, 6'h??}: state = JAL;
        //     {6'h00, 6'h08}: state = JR;
        //     {6'h00, 6'h09}: state = JALR;
        //     {6'h23, 6'h??}: state = LW;
        //     {6'h2b, 6'h??}: state = SW;
        //     {6'h0f, 6'h??}: state = LUI;
        //     {6'h1c, 6'h02}: state = MUL;
        //     default:        state = ADD;
        // endcase

        if      (opcode == 6'h00 && funct == 6'h20) state = ADD;
        else if (opcode == 6'h00 && funct == 6'h21) state = ADDU;
        else if (opcode == 6'h00 && funct == 6'h22) state = SUB;
        else if (opcode == 6'h00 && funct == 6'h23) state = SUBU;
        else if (opcode == 6'h08)                   state = ADDI;
        else if (opcode == 6'h09)                   state = ADDIU;
        else if (opcode == 6'h00 && funct == 6'h24) state = AND;
        else if (opcode == 6'h00 && funct == 6'h25) state = OR;
        else if (opcode == 6'h00 && funct == 6'h26) state = XOR;
        else if (opcode == 6'h00 && funct == 6'h27) state = NOR;
        else if (opcode == 6'h0c)                   state = ANDI;
        else if (opcode == 6'h00 && funct == 6'h00) state = SLL;
        else if (opcode == 6'h00 && funct == 6'h02) state = SRL;
        else if (opcode == 6'h00 && funct == 6'h03) state = SRA;
        else if (opcode == 6'h00 && funct == 6'h2a) state = SLT;
        else if (opcode == 6'h00 && funct == 6'h2b) state = SLTU;
        else if (opcode == 6'h0b)                   state = SLTIU;
        else if (opcode == 6'h04)                   state = BEQ;
        else if (opcode == 6'h05)                   state = BNE;
        else if (opcode == 6'h06)                   state = BLEZ;
        else if (opcode == 6'h07)                   state = BGTZ;
        else if (opcode == 6'h01)                   state = BLTZ;
        else if (opcode == 6'h02)                   state = J;
        else if (opcode == 6'h03)                   state = JAL;
        else if (opcode == 6'h00 && funct == 6'h08) state = JR;
        else if (opcode == 6'h00 && funct == 6'h09) state = JALR;
        else if (opcode == 6'h23)                   state = LW;
        else if (opcode == 6'h2b)                   state = SW;
        else if (opcode == 6'h0f)                   state = LUI;
        else if (opcode == 6'h1c && funct == 6'h02) state = MUL;
        else                                        state = ADD;
    end

    always @(*) begin
        RegWr = (state == BEQ || state == BLEZ || state == BGTZ || state == BLTZ || state == J || state == JR || state == SW)? 0 : 1;
        MemWr = (state == SW)? 1 : 0;
        RegDst = (state == JAL || state == JALR)? 2 :
                 (state == ADDI || state == ADDIU || state == ANDI || state == SLTIU || state == LW || state == LUI)? 1 : 0;
        MemtoReg = (state == LUI)? 3 : (state == JAL)? 2 : (state == LW)? 1 : 0;
        ALUSrc = (state == ADDI || state == ADDIU || state == ANDI || state == SLTIU || state == LW || state == SW)? 1 : 0;
        ExtOp = (state == ANDI)? 0 : 1;
        ALUConf = (state == ADD || state == ADDI)? 0 : (state == ADDU || state == ADDIU)? 1 : (state == SUB)? 2 : (state == SUBU)? 3 :
                  (state == AND || state == ANDI)? 4 : (state == OR)? 5 : (state == XOR)? 6 : (state == NOR)? 7 :
                  (state == SLL)? 8 : (state == SRL)? 9 : (state == SRA)? 10 : (state == SLT)? 11 : (state == SLTU || state == SLTIU)? 12 :
                  (state == MUL)? 13 : 0;
        BranchConf = (state == BEQ)? 1 : (state == BNE)? 2 : (state == BLEZ)? 3 : (state == BGTZ)? 4 : (state == BLTZ)? 5 : 0;
        Jump = (state == J || state == JAL || state == JR || state == JALR)? 1 : 0;
        Jr = (state == JR || state == JALR)? 1 : 0;
    end

endmodule


module RF (
    input   clk,
    input   rst,
    input   RegWr,
    input   [4 : 0]     rs,
    input   [4 : 0]     rt,
    input   [4 : 0]     rw,
    output  [31 : 0]    busA,
    output  [31 : 0]    busB,
    input   [31 : 0]    busW,
    output  [31 : 0]    JrAddr
);

    reg     [31 : 0]    RegFile [31 : 0];

    integer i;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                RegFile[i] <= 32'h0000_0000;
            end
        end
        else if (RegWr && rw != 0) begin
            RegFile[rw] <= busW;
        end
    end

    assign  busA = (RegWr && rw != 0 && rw == rs)? busW : RegFile[rs];
    assign  busB = (RegWr && rw != 0 && rw == rt)? busW : RegFile[rt];
    assign  JrAddr = RegFile[rs];

endmodule


module ID (
    input               clk,
    input               rst,

    input   [31 : 0]    inst,
    input   [31 : 0]    pc,
    output  [4 : 0]     rs,
    output  [4 : 0]     rt,
    output  [4 : 0]     rw,
    output  [4 : 0]     shamt,
    output  [31 : 0]    ExtImm32,
    output  [31 : 0]    LuiImm32,
    output  [31 : 0]    JumpAddr,
    output  [31 : 0]    busA,
    output  [31 : 0]    busB,

    output              RegWr,
    output              MemWr,
    output  [1 : 0]     MemtoReg,
    output              ALUSrc,
    output  [3 : 0]     ALUConf,
    output  [2 : 0]     BranchConf,
    output              Jump,

    input               RegWr_in,
    input   [31 : 0]    busW_in,
    input   [4 : 0]     rw_in
);

    wire    [31 : 0]    JAddr;
    wire    [31 : 0]    JrAddr;
    assign  JumpAddr = (Jr == 1)? JrAddr : JAddr;

    wire    [1 : 0]     RegDst;
    wire    [4 : 0]     rd;
    assign  rw = (RegDst == 2)? 31 : (RegDst == 1)? rt : rd;

    wire    [15 : 0]    imm16;
    assign  ExtImm32 = (ExtOp == 1)? {{16{imm16[15]}}, imm16} : {16'h0000, imm16};
    assign  LuiImm32 = {imm16, 16'h0000};

    DECODER u_DECODER (
        .inst(inst),
        .pc(pc),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .shamt(shamt),
        .imm16(imm16),
        .JAddr(JAddr),

        .RegWr(RegWr),
        .MemWr(MemWr),
        .RegDst(RegDst),
        .MemtoReg(MemtoReg),
        .ALUSrc(ALUSrc),
        .ExtOp(ExtOp),
        .ALUConf(ALUConf),
        .BranchConf(BranchConf),
        .Jump(Jump),
        .Jr(Jr)
    );

    RF u_RF (
        .clk(clk),
        .rst(rst),
        .RegWr(RegWr_in),
        .rs(rs),
        .rt(rt),
        .rw(rw_in),
        .busA(busA),
        .busB(busB),
        .busW(busW_in),
        .JrAddr(JrAddr)
    );

endmodule