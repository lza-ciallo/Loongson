// Type
`define     ALU_TYPE    0
`define     MDU_TYPE    1
`define     LSU_TYPE    2
`define     BRU_TYPE    3
`define     DIR_TYPE    4
`define     JIRL_TYPE   5
`define     CSR_TYPE    6

// ALU
`define     ADD_CONF    0
`define     SUB_CONF    1
`define     SLT_CONF    2
`define     SLTU_CONF   3
`define     NOR_CONF    4
`define     AND_CONF    5
`define     OR_CONF     6
`define     XOR_CONF    7
`define     SLL_CONF    8
`define     SRL_CONF    9
`define     SRA_CONF    10

// MDU
`define     MUL_CONF    0
`define     MULH_CONF   1
`define     MULHU_CONF  2
`define     DIV_CONF    3
`define     DIVU_CONF   4
`define     MOD_CONF    5
`define     MODU_CONF   6

// LSU
`define     LDB_CONF    0
`define     LDH_CONF    1
`define     LDW_CONF    2
`define     STB_CONF    3
`define     STH_CONF    4
`define     STW_CONF    5
`define     LDBU_CONF   6
`define     LDHU_CONF   7

// BRU
`define     BEQ_CONF    0
`define     BNE_CONF    1
`define     BLT_CONF    2
`define     BGE_CONF    3
`define     BLTU_CONF   4
`define     BGEU_CONF   5
`define     JIRL_CONF   6

// DIR
`define     NONE_CONF   0
`define     CNTID_CONF  1
`define     CNTVL_CONF  2
`define     CNTVH_CONF  3

// CSR
`define     CSRRD_CONF  0
`define     CSRWR_CONF  1
`define     CSRXG_CONF  2