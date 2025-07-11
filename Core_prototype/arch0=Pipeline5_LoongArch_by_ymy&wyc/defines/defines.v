`ifndef DEFINES
`define DEFINES

//-------- INSTRUCTION DECODE ---------//

// INT ARITHMATIC //
// R
`define ADD     32'b00000_0000_0010_0000_?????_?????_?????
`define SUB     32'b00000_0000_0010_0010_?????_?????_?????
`define SLT     32'b00000_0000_0010_0100_?????_?????_?????
`define SLTU    32'b00000_0000_0010_0101_?????_?????_?????
`define MUL     32'b00000_0000_0011_1000_?????_?????_?????
`define MULH    32'b00000_0000_0011_1001_?????_?????_?????  //TODO
`define MULHU   32'b00000_0000_0011_1010_?????_?????_?????  //TODO
`define DIV     32'b00000_0000_0100_0000_?????_?????_?????
`define DIVU    32'b00000_0000_0100_0010_?????_?????_?????
`define MOD     32'b00000_0000_0100_0001_?????_?????_?????  //TODO
`define MODU    32'b00000_0000_0100_0011_?????_?????_?????  //TODO
// I
`define ADDI    32'b00_0000_1010_????????????_?????_?????
`define SLTI    32'b00_0000_1001_????????????_?????_?????
`define SLTUI   32'b00_0000_1001_????????????_?????_?????
`define LU12I   32'b000_1010_????????????????????_?????
`define PCADDU12I 32'b000_1110_????????????????????_?????

// INT LOGIC //
// R
`define AND     32'b00000_0000_0010_1001_?????_?????_?????
`define OR      32'b00000_0000_0010_1010_?????_?????_?????
`define NOR     32'b00000_0000_0010_1000_?????_?????_?????
`define XOR     32'b00000_0000_0010_1011_?????_?????_?????
// I
`define ANDI    32'b00_0000_1010_????????????_?????_?????
`define ORI     32'b00_0000_1110_????????????_?????_?????
`define XORI    32'b00_0000_1111_????????????_?????_?????

// SHIFT //
// R
`define SLL     32'b00000_0000_0010_1110_?????_?????_?????
`define SRL     32'b00000_0000_0010_1111_?????_?????_?????
`define SRA     32'b00000_0000_0011_0000_?????_?????_?????
// I
`define SLLI    32'b00000_0000_1000_0001_?????_?????_?????
`define SRLI    32'b00000_0000_1000_1001_?????_?????_?????
`define SRAI    32'b00000_0000_1001_0001_?????_?????_?????

// MEM ACCESS //
// R
`define LDB     32'b00_1010_0000_????????????_?????_?????
`define LDH     32'b00_1010_0001_????????????_?????_?????
`define LDW     32'b00_1010_0010_????????????_?????_?????
`define LDBU    32'b00_1010_1000_????????????_?????_?????
`define LDHU    32'b00_1010_1001_????????????_?????_?????
`define STB     32'b00_1010_0100_????????????_?????_?????
`define STH     32'b00_1010_0101_????????????_?????_?????
`define STW     32'b00_1010_0110_????????????_?????_?????
`define PRELD   32'b00_1010_1011_????????????_?????_????? 
// I
`define LL      32'b0010_0000_??????????????_?????_????? 
`define SC      32'b0010_0001_??????????????_?????_????? 

// BRANCH //
`define BEQ     32'b01_0110_????????????????_?????_?????
`define BNE     32'b01_0111_????????????????_?????_?????
`define BLT     32'b01_1000_????????????????_?????_?????
`define BGE     32'b01_1001_????????????????_?????_?????
`define BLTU    32'b01_1010_????????????????_?????_?????
`define BGEU    32'b01_1011_????????????????_?????_?????
`define B       32'b01_0100_????????????????_?????_?????        // j
`define BL      32'b01_0101_????????????????_?????_?????        // jl
`define JIRL    32'b01_0011_????????????????_?????_?????        // jr

// BAR(STALL) //
`define DBAR    32'b00111_0000_1110_0100_???????????????
`define IBAR    32'b00111_0000_1110_0101_???????????????

// OTHERS //
`define SYSCALL 32'b00000_0000_0101_0110_???????????????
`define BREAK   32'b00000_0000_0101_0100_???????????????
`define RDCNTVL 32'b000_0000_0000_0000_0011_000_00000_?????
`define RDCNTVH 32'b000_0000_0000_0000_0011_001_00000_?????
`define RDCNTID 32'b 000_0000_0000_0000_0011_001_?????_00000

// PRIVILEGE CSR //
`define CSRRD   32'b0000_0100_??????????????_00000_?????
`define CSRWR   32'b0000_0100_??????????????_00001_?????
`define CSRXCHG 32'b0000_0100_??????????????_?????_?????

// PRIVILEGE CACHE //
`define CACOP   32'b00_0001_1000_????????????????_?????_?????

// PRIVILEGE OTHERS //
`define ERTN    32'b00_0001_1001_0010_0000_1110_00000_00000
`define IDLE    32'b 00000_1100_1001_0001_???????????????




//--------- ALUOP ----------//
`define ALU_ADD      5'b00000   
`define ALU_SUB      5'b00001   
`define ALU_SLT      5'b00010   
`define ALU_SLTU     5'b00011   
`define ALU_AND      5'b00100   
`define ALU_NOR      5'b00101   
`define ALU_OR       5'b00110   
`define ALU_XOR      5'b00111   
`define ALU_SLL      5'b01000   
`define ALU_SRL      5'b01001   
`define ALU_SRA      5'b01010   
`define ALU_LUI      5'b01011   
`define ALU_ANDN     5'b01100   
`define ALU_ORN      5'b01101   
`define ALU_MUL      5'b01110     // TODO:后续改为单独模块处理
`define ALU_DIV      5'b01111     // TODO:后续改为单独模块处理
`define ALU_DEFAULT  5'b00000




`endif



