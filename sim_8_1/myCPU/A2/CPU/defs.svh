`include "./defs/inst_def.svh"
`include "./defs/decode_def.svh"
`include "./defs/excp_def.svh"

`define     START_PC            32'h1c00_0000
`define     IMEM_MIN            32'h0000_0000
`define     IMEM_MAX            32'hFFFF_FFFF
`define     DMEM_MIN            32'h0000_0000
`define     DMEM_MAX            32'hFFFF_FFFF

// PROCESSOR CONFIGURATION

`define     INST_FETCH_WIDTH    4
`define     INST_DECODER_WIDTH  3
`define     ISSUE_WIDTH         6   // ALU, MDU, LSU, DIR, CSR, BRU
`define     CDB_WIDTH           5   // ALU, MDU, LSU, DIR, CSR
`define     ROB_COMMIT_WIDTH    5

`define     ISSUEQ_DEPTH        16
`define     IFIFO_DEPTH         32
`define     DFIFO_DEPTH         16
`define     CSRFIFO_DEPTH       16
`define     BTB_DEPTH           64
`define     ROB_DEPTH           64

`define     ARF_NUM             32
`define     PRF_NUM             64

`define     MIN_PIPELINE_DEPTH  9   // IF1, IF2, ID, rename, dispatch, issue, read, EX, WB