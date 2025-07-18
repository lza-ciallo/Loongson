`ifndef     DEFINES
`define     DEFINES

`include "./defines/inst_def.svh"

// 处理器配置
`define     PC_WIDTH            32
`define     INST_WIDTH          32
`define     DATA_WIDTH          32

`define     INST_FIFO_DEPTH     16
`define     ISSUE_QUEUE_DEPTH   16
`define     DATA_FIFO_DEPTH     16
`define     ROB_DEPTH           128

`define     ARF_NUM             32
`define     PRF_NUM             64
`define     ISSUE_QUEUE_NUM     6
`define     RESULT_NUM          4

`endif