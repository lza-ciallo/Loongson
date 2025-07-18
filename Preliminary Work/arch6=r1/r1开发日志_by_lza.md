# core_r1 #

## 7/14 ##

### 部分关键时序模块的行为描述 ###

- PC:
    - 输出 pc;
    - **Commit** 发现分支预测失败, 回退为 pc_unsel;
    - **ID** 发现跳转指令, 改为 pc_jump;
    - **IF&Predict** 发现分支指令, 改为 pc_predict.

- Branch_Predictor:
    - 输入 pc, 输出 pc_predict;
    - **ID** 初次发现跳转指令, 将 BTB 的 pc_decode 地址处写入 pc_branch;
    - **Commit** 调整 PHT, 并弹出 pc_unsel.

- sRAT:
    - 输入 Ra, Rb, Rw, 分配 Pw, 读取 Pa, Pb, Pw_old, valid_Pa, valid_Pb;
    - 对于写寄存器指令, 修改 P_list, valid_list, free_list;
    - 接收 **EX** 结果广播, 释放 valid_list;
    - **Commit** 释放 free_list;
    - 精确异常恢复, 写入aRAT_P_list, aRAT_free_list.

- Issue_Queues:
    - 在分配条目内, 写入对应指令的 tag_ROB, P, valid 和其他必要信息;
    - 读取 ROB 的 ptr_old, 采用 oldest-first 唤醒方式;
    - 接收 **EX** 结果广播 (LSQ 还接收 AGU 特殊广播), 修改 valid.

- ROB:
    - **Rename&Dispatch** 阶段分配 tag_ROB, 在此预写入 Rw, Pw, 和是否写寄存器等配置信息;
    - 接收 **EX** 结果广播, 修改 ready;
    - **Commit** 提交指令到 aRAT 和 sRAT, 更新 ptr_old.

### 尝试实现极简版LA32子集 (14) ###

- ALU (4):
    | add rd, rj, rk | rd = rj + rk | `17'h00020` + rk + rj + rd |
    | - | - | - |
    | slt rd, rj, rk | rd = (signed(rj) < signed(rk))? 1 : 0 | `17'h00024` + rk + rj + rd |
    | addi rd, rj, imm12 | rd = rj + SignExt(imm12) | `10'h00a` + imm12 + rj + rd |
    | slti rd, rj, imm12 | rd = (signed(rj) < signed(SignExt(imm12)))? 1 : 0 | `10'h008` + imm12 + rj + rd |

- MDU (3):
    | mul rd, rj, rk | rd = rj * rk [31:0] | `17'h00038` + rk + rj + rd |
    | - | - | - |
    | mulh rd, rj, rk | rd = signed(rj) * signed(rk) [63:32] | `17'h00039` + rk + rj + rd |
    | mulhu rd, rj, rk | rd = unsigned(rj) * unsigned(rk) [63:32] | `17'h0003a` + rk + rj + rd |

- LSU (3):
    | ldw rd, rj, imm12 | rd = mem[rj + SignExt(Imm12)] | `10'h0a2` + imm12 + rj + rd |
    | - | - | - |
    | stw rd, rj, imm12 | mem[rj + SignExt(Imm12)] = rd | `10'h0a6` + imm12 + rj + rd |
    | dbar hint15=0 | - | `17'h070e4` + hint15 |

- BRU (1):
    | beq rj, rd, offs16 | if rj == rd: PC = PC + SignExt({offs16, 2'0}) |`6'h16` + offs16 + rj + rd |
    | - | - | - |

- 直通 (2 (!+1)):
    | bl offs26 | r1 = PC + 4, PC = PC + SignExt({offs16, 2'0}) | `6'h15` + offs[15:0] + offs[25:16] |
    | - | - | - |
    | lu12i rd, imm20 | rd = {imm20, 12'0} | `7'0a` + imm20 + rd |
    | b offs26 | PC = PC + SignExt({offs16, 2'0}) (ID跳转, nop存队列) | `6'h14` + offs[15:0] + offs[25:16] |
