`include "../defines/defines.v"

module Control (
    // INSTRUCTION
    input wire [31:0] instr,

    // DATAS
    output wire [ 5:0] rk,      // regAddrs
    output wire [ 5:0] rj,
    output wire [ 5:0] rd,
    output wire [11:0] imm12,   // 12bit imm
    output wire [15:0] imm16,   // 16bit imm offset
    output wire [25:0] imm26,   // 26bit imm offset 

    // CONTROL SIGNALS
    output wire       regwr,    // WriteAddr
    output wire       memwr,    // MemWr
    output wire       memrd,    // MemRead
    output wire       alusrc,   // ALUSrc
    output wire [1:0] regdst,   // RegDst
    output wire       mem2reg,  // MemtoReg
    output wire       branch,   // Branch
    output wire [1:0] jump,     // Jump
    output wire [4:0] aluop     // ALUOp
);

    // DATAS DECODE
    assign rk = instr[14:10];
    assign rj = instr[9:5];
    assign rd = instr[4:0];
    assign imm12 = instr[21:10];
    assign imm16 = instr[25:10];
    assign imm26 = {instr[9:0],instr[25:10]};

    // CONTROL SIGNALS DECODE
    assign regwr = (instr == `STW 
                            |`BEQ
                            |`BNE
                            |`BLT
                            |`BGE
                            |`BLTU
                            |`BGEU
                            |`B
                            |`BL) ? 0:1;
                            
    assign memwr = (instr == `STW) ? 1:0;
    assign memrd = (instr == `LDW) ? 1:0;
    assign alusrc = (instr == `ADDI
                            |`SLTI
                            |`ANDI
                            |`SLLI
                            |`SRLI
                            |`SRAI
                            |`LDW
                            |`STW) ? 0:1;
    assign regdst = (instr == `ADDI
                            |`SLTI
                            |`ANDI
                            |`SLLI
                            |`SRLI
                            |`SRAI
                            |`LDW
                            |`STW
                            |`BEQ 
                            |`BNE 
                            |`BLT 
                            |`BGE 
                            |`BLTU
                            |`BGEU
                            |`B   
                            |`BL) ? 0:1;
    assign mem2reg = (instr == `LDW) ? 1:0;
    assign branch = (instr == |`BEQ 
                            |`BNE 
                            |`BLT 
                            |`BGE 
                            |`BLTU
                            |`BGEU) ? 1:0;
    assign jump = (instr == `JIRL) ? 2'b10 : 
                    (instr == `B |`BL) ? 2'b01 : 2'b00;
    assign aluop = (instr == `ADD |`ADDI |`LDW |`STW) ? `ALU_ADD :
                    (instr == `SUB)                   ? `ALU_SUB :
                    (instr == `SLT |`SLTI)            ? `ALU_SLT :
                    (instr == `SLTU)                  ? `ALU_SLTU:                
                    (instr == `MUL)                   ? `ALU_MUL :  
                    (instr == `DIV)                   ? `ALU_DIV :
                    (instr == `AND |`ANDI)            ? `ALU_AND :
                    (instr == `OR |`ORI)              ? `ALU_OR  :
                    (instr == `NOR)                   ? `ALU_NOR :
                    (instr == `XOR |`XORI)            ? `ALU_XOR :
                    (instr == `SLL |`SLLI)            ? `ALU_SLL :
                    (instr == `SRL |`SRLI)            ? `ALU_SRL :
                    (instr == `SRA |`SRAI)            ? `ALU_SRA : `ALU_DEFAULT;

endmodule






