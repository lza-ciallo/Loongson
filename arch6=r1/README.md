| 版本 | 进度 |
| - | - |
| R1 | 行为级仿真支持大部分基础指令集 |
| R2 | MDU 接入 IP, 实现了可接受的时序和面积 |

---

# core_R1 #

## Elaboration ##

- <u>*define*</u>: **defs.svh** 等三个头文件必须删除`ifndef-define`块, 否则默认不存在; **MASK** 模块同理, 以`Conf`取代宏定义, 以配置输出掩码.

- <u>*casez*</u>: **PREDECODER**, **FREELIST** 等的优先级编码中, `generate+casez`块容易遗漏`always @(*)`.

## Simulation ##

### alu: ###

- <u>*mem*</u>: **IMEM**, **DMEM** 无法完全模仿 BRAM 行为, 必须`clk+rst`成对出现, 否则疑似会把`always @(posedge clk)`块视为仅执行一次, 表现为`inst`只输出前三条.

### mem: ###

- <u>*lsuQ*</u>: **LSUQ** 的半乱序唤醒逻辑出现致命错误, 修改为**写入时密堆积, 唤醒时排空气泡**.

- 同时修正了 **LSUQ** 半乱序唤醒的复杂掩码中的一些笔误, 如`+/-`, `i/1`.

- 后续发现 **ROB** 卡在最后几条指令, 发现是 **LSUQ** 密堆积写入时`write_index`赋值笔误, 导致写入指令错位, 修正后顺利通过.

### loop1: ###

- 设计其结束时陷入 B 的自循环中, 故 tb 中无法调用其写入`r0`的伪异常作为结束标志, 重新设计为陷入 B 的自循环为结束标志.

- <u>*mask*</u>: 发现`r1=10`, `r2=11`, `r3=10`, 取指端行为均正常, **sRAT** 值为10, **aRAT** 值为11, 鉴定为 **ROB** 的 **MASK** 未考虑置预测失败后指令为无效, 添加选择逻辑.

### loop2: ###

- <u>*aRAT*</u>: 观察到分支预测恢复时, **ROB** 提交的指令可能为`add+beq+...`, 第一条`add`在 **aRAT** 传递恢复值给 **sRAT** 时需要被旁路, 为此 tb 内刻意构造出同时准备好提交的`add+beq+...`形式.

- 同时为了后期综合, 提前修改 **aRAT** 写入逻辑, 避免重复写入.

### fibonacci: ###

- 顺利通关.

- 同时为了对接 **ICache**, 修改为**4取指-3译码-5发射-5提交**, 前面测试依旧能正常通过.

## Synthesis & Implementation ##

- 仅有`clk+rst`输入, 无输出的模块会被优化, 故 **myCPU** 模块需要设置若干 debug 专用输出端口.

- Implementation 结果: 面积几乎占满, 50MHz 时序未达标, 关键路径为 **MDU**.
- 未来修改: **IFIFO**`64->32`, **ROB**`128->64`, **MDU**调用 `mul`, `div`, `mod`的 IP 核, 周期数设计`1:16:16`, 需要开一个`entry_num=32`的 **BUFFER**, 同时修改级间寄存器.

- 兼修复了**EX-CDB**级间寄存器的位宽错误.

---

# core_R2 #

- <u>*<inst_fetch, commit_unit>*</u> **IFIFO**: `64->32`, **ROB**: `128->64`, 为此修改 tag_rob & ptr_old: `[6:0]->[5:0]`.

- <u>*<back_end>*</u> 删去统一的 **EX-CDB** 级间寄存器, 改为各 FU 内嵌的输出寄存器.

- <u>*<inst_fetch, back_end>*</u> 独立出 **IMEM**, **DMEM** 的端口.

- <u>*<back_end>*</u> 将 **MDU** 修改为 `mul=1,div=mod=16`.

- <u>*<back_end>*</u> 修正了 **mul_wrapper**, **div_wrapper** 中 Conf 的时序混乱问题.

- <u>*<issue_queue, back_end>*</u> 修复了 **DIRQ** 的 awake 寄存器, **MDU** 的 CDB 输出寄存器的锁存 bug.

*未接 cache 的 myCPU 当前可以实现 50MHz 的时序性能, 50% 的面积性能.*

---

# core_R3 #

- JIRL 适配设计:

  - ***inst_fetch*** 阶段 JIRL 视为特殊的 Branch, **RSB** 代替原 Branch 的静态解码, 在**predecoder** 中提供查询 `target_branch` 的功能.

  - ***issue_queue*** 中 **BRUQ** 输入 `rd`,`rj`,`imm=SignExt(offs<<2)`,`target_branch_predict`, **DIRQ** 新增一个 `pc` 输入端口, 与原先的 `imm` 端口进行选择.

  - ***back_end*** 阶段 **BRU** 计算 JIRL 是否预测成功, **ROB** 中默认 `Branch=1`, 写入计算结果 `target_branch_real`,`Predict=1/0`, 匹配成功或失败都使 **PHT** 继续强化跳转.
