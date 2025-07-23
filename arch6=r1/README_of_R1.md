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

- 同时为了对接 **ICache**, 修改为**4取指-3发射-5执行-5提交**, 前面测试依旧能正常通过.

## Synthesis & Implementation ##

- 仅有`clk+rst`输入, 无输出的模块会被优化, 故 **myCPU** 模块需要设置若干 debug 专用输出端口.

- Implementation 结果: 面积几乎占满, 50MHz 时序未达标, 关键路径为 **MDU**.
- 未来修改: **IFIFO**`64->32`, **ROB**`128->64`, **MDU**调用 `mul`, `div`, `mod`的 IP 核, 周期数设计待定.