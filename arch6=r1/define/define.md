# define内容

1.基本配置

（可以统一一下width, size, num...的命名规则）


| Parameter      | Meaning                        | Default |
| -------------- | ------------------------------ | ------- |
| PC_WIDTH       | 指令位宽                       | 32      |
| REG_WIDTH      | 寄存器位宽                     | 32      |
| PRF_SIZE       | 物理寄存器容量                 |         |
| PRF_ADDR_WIDTH | 物理寄存器地址位宽             |         |
| ARF_SIZE       | 逻辑寄存器容量                 |         |
| ARF_ADDR_WIDTH | 逻辑寄存器地址位宽             |         |
| ROB_SIZE       | 重排序缓冲容量                 |         |
| ROB_ADDR_WIDTH | 重排序缓冲entr位宽             |         |
| MACHINE_NUM    | 每cc最多**取指**指令数目 |         |
| ISSUE_NUM      | 每cc最多**发射**指令数目 |         |
| RETIRE_NUM     | 每cc最多**退休**指令数目 |         |


2.模块重要端口、接线定义 （clk, rst等信号暂略）


| Stage(.Model) | Port                   | Wire          | I/O | Width     | From Stage     | Meaning                       |
| ------------- | ---------------------- | ------------- | --- | --------- | -------------- | ----------------------------- |
| IF            | inst_1                 | inst_1        | o   | REG_WIDTH | -              | 每cc取得的指令的机器码        |
|               | inst_2                 | inst_2        | o   | REG_WIDTH | -              | 同上                          |
|               | inst_3                 | inst_3        | o   | REG_WIDTH | -              | 同上                          |
|               | inst_4                 | inst_4        | o   | REG_WIDTH | -              | 同上                          |
|               | pc_if                  | pc_if         | o   | PC_WIDTH  | -              | 当前阶段PC, BTB更新时将会有用 |
|               | jump                   | jump          | i   | 1         | ID             | 解码识别到无条件跳转          |
|               | pc_jump                | pc_jump       | i   | PC_WIDTH  | ID             | 算得无条件跳转地址            |
|               | branch                 | branch        | i   | 1         | ID             | 已判断好的是否分支条件        |
|               | btb_renew              | btb_renew     | i   | 1         | EX             | btb更新使能                   |
|               | pc_ex                  | pc_ex         | i   | PC_WIDTH  | EX             | btb更新分支指令值             |
|               | ...                    |               | i   |           | EX             | btb更新具体内容               |
|               |                        |               |     |           |                |                               |
| ID            | inst_1(2,3,4)          | inst_1(2,3,4) | i   | REG_WIDTH | IF             | IF阶段获得的机器码指令        |
|               | pc_if                  | pc_if         | i   | PC_WIDTH  | IF             | 刚刚从取值阶段传来的PC        |
|               | jump                   | jump          | o   | 1         | -              | 解码确认为jump指令            |
|               | pc_jump                | pc_jump       | o   | PC_WIDTH  | -              | 无条件跳转的目的pc地址        |
|               | branch                 | branch        | o   | 1         | -              | 是否分支条件                  |
|               | global_type_1(2,3,4)   |               | o   |           | -              |                               |
|               | alu_type_1(2,3,4)      |               | o   |           | -              |                               |
|               | alu_sign_1(2,3,4)      |               | o   |           | -              |                               |
|               | ext_sign_1(2,3,4)      |               | o   |           | -              |                               |
|               | u_or_l_1(2,3,4)        |               | o   |           | -              |                               |
|               | w_h_b_1(2,3,4)         |               | o   |           | -              | word, halfword或byte          |
|               | rk_1(2,3,4)            |               | o   |           | -              |                               |
|               | rj_1(2,3,4)            |               | o   |           | -              |                               |
|               | rd_1(2,3,4)            |               | o   |           | -              |                               |
|               | ...                    |               |     |           |                |                               |
|               |                        |               |     |           |                |                               |
| RENAME        | rk_1(2,3,4)            |               | i   |           | ID             |                               |
|               | rj_1(2,3,4)            |               | i   |           | ID             |                               |
|               | rd_1(2,3,4)            |               | i   |           | ID             |                               |
|               | pk_1(2,3,4)            |               | o   |           | -              |                               |
|               | pj_1(2,3,4)            |               | o   |           | -              |                               |
|               | pd_1(2,3,4)            |               | o   |           | -              |                               |
|               | flush                  |               | i   |           |                | 刷洗                          |
|               | exp                    |               | i   |           |                | 异常                          |
|               | arat_wr                |               | i   |           |                | arat更新使能                  |
|               | ...                    |               |     |           |                |                               |
|               |                        |               |     |           |                |                               |
| ISSUE         | pk_1(2,3,4)            |               | i   |           |                |                               |
|               | pj_1(2,3,4)            |               | i   |           |                |                               |
|               | pd_1(2,3,4)            |               | i   |           |                |                               |
|               | wakeup_prf             |               | i   |           | EX(每个FU一条) | 唤醒总线                      |
|               | wakeup_valid           |               | i   |           | EX             |                               |
|               | ptr_old                |               | i   |           | ROB            | ROB头指针                     |
|               | ptr_new                |               | i   |           | ROBllll;lk     | ROB尾指针                     |
|               | ...                    |               |     |           |                |                               |
|               |                        |               |     |           |                |                               |
|               |                        |               |     |           |                |                               |
|               |                        |               |     |           |                |                               |
| EX            | ...                    |               |     |           |                |                               |
|               |                        |               |     |           |                |                               |
|               |                        |               |     |           |                |                               |
|               |                        |               |     |           |                |                               |
| COMMIT        | tag_rob                |               | i   |           | EX             |                               |
|               | valid_request          |               | i   |           | EX             |                               |
|               | exp                    |               | i   |           | EX             |                               |
|               | Freelist_release_addr  |               | o   |           | -              |                               |
|               | Freelist_release_valid |               | o   |           | -              |                               |
|               | arat_addr              |               | o   |           | -              |                               |
|               | arat_value             |               | o   |           | -              |                               |
|               | arat_update_valid      |               | o   |           | -              |                               |
|               |                        |               |     |           |                |                               |
|               |                        |               |     |           |                |                               |
|               |                        |               |     |           |                |                               |
|               |                        |               |     |           |                |                               |
|               |                        |               |     |           |                |                               |
|               |                        |               |     |           |                |                               |
|               |                        |               |     |           |                |                               |
|               |                        |               |     |           |                |                               |


3.指令解码

```c
//-------- INSTRUCTION DECODE ---------//

// INT ARITHMATIC //
// R
`define ADD     32'b00000_0000_0010_0000_?????_?????_?????
`define SUB     32'b00000_0000_0010_0010_?????_?????_?????
`define SLT     32'b00000_0000_0010_0100_?????_?????_?????
`define SLTU    32'b00000_0000_0010_0101_?????_?????_?????
`define MUL     32'b00000_0000_0011_1000_?????_?????_?????
`define MULH    32'b00000_0000_0011_1001_?????_?????_?????
`define MULHU   32'b00000_0000_0011_1010_?????_?????_?????
`define DIV     32'b00000_0000_0100_0000_?????_?????_?????
`define DIVU    32'b00000_0000_0100_0010_?????_?????_?????
`define MOD     32'b00000_0000_0100_0001_?????_?????_?????
`define MODU    32'b00000_0000_0100_0011_?????_?????_?????
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
`define ALU_MUL      5'b01110
`define ALU_DIV      5'b01111
`define ALU_DEFAULT  5'b00000




`endif




```

注：

- 感觉HIT开源项目的interface结构使用是可以借鉴的，个人感觉对代码可读性和修改流程有很大改善
