| 版本 | 进度 |
| - | - |
| R1 | 行为级仿真支持大部分基础指令集 |
| R2 | MDU 接入 IP, 实现了可接受的时序和面积 |
| R3 | 支持非预测性的 JIRL |
| R4 | 支持预测性的 JIRL |

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

- 修正 **inst_fetch.BPU.PHT** 的"第一次写入"问题:
    ```
    // learn from predecoder
    for (integer i = 0; i < 4; i = i + 1) begin
        if (isBranch[i]) begin
            btb[i].occupied <=  1;
            btb[i].tag      <=  pc_write[i][31 : 10];
            btb[i].target   <=  target_write[i];
        end
    end
    ```
    $\Rightarrow$
    ```
    // learn from predecoder
    for (integer i = 0; i < 4; i = i + 1) begin
        if (isBranch[i]) begin
            btb[pc_write[i][9 : 2]].occupied    <=  1;
            btb[pc_write[i][9 : 2]].tag         <=  pc_write[i][31 : 10];
            btb[pc_write[i][9 : 2]].target      <=  target_write[i];
        end
    end
    ```

- 修正 **inst_fetch.predecoder** 的 Jump 生成逻辑(即 **inst_fetch.IFREG** 置无效):
    ```
    // Jump
    assign  Jump            =   hint & (isJump_r[3] | isJump_r[2] | isJump_r[1] | isJump_r[0]);
    ```
    $\Rightarrow$
    ```
    // Jump
    assign  Jump            =   (valid_inst[3] & isJump_r[3]) | (valid_inst[2] & isJump_r[2]) |
                                (valid_inst[1] & isJump_r[1]) | (valid_inst[0] & isJump_r[0]);
    ```

- 将 JIRL 分拆为"判断预测是否正确"与"GR[rd]=PC+4"两个任务, 后者由 **issue_queue.dirQ** 发射并作 `isJIRL_dir=1` 记号, 不可置 **ROB** `ready=1`.

- 取指部分 **inst_fetch.predecoder** 须先标注 JIRL 为 `isBranch=1`, 用来预写入 **ROB**.

- 预测失败恢复 debug 时, 修复了 **commit_unit.aRAT.free_list_arat** 的"写0"问题.

- 兼容 JIRL 与 Branch, 额外写入 `target_real`, 正确的实现方法见 R4.

---

# core_R4 #

### *bl_jirl(fibonacci_pro)* 测试程序 debug (R3 & R4): ###

- 修复了 **LSU.DFIFO** 申请写入 **DMEM** 的队列冲刷错误, 只能清空 `need_store=0` 的条目. 加入 `ptr_wait` 机制, 已退休的 Store 指令会脱离 flush 的约束. (大改)

- **ROB** 必须视 JIRL 为 `Predict=0/1`, `Branch=1`, 否则 **PC** 会根据 `Branch` 选择写入 `pc_rob+4` 还是 `target_rob`.

- 修复了 **DIRQ** 密堆积写入时的 `isJIRL` 标签问题.

- 修复了 **ROB.MASK** 对 Branch, Store 指令同时退休时的错误处理, 采用保守方法, 不退休 Branch 以后的任何指令, 以避免预测失败.

- 取消引入 **RSB**, 直接用 **BTB** 存放 JIRL 跳转地址, 但写入只能在初见预测失败时 **ROB** 引回来. **predecoder** 产生的 JIRL 目标地址无效, 被 MUX 筛掉.

- 标准递归调用测试程序 *bl_jirl(fibonacci)* 的执行时间:

    | R# | Conf_mask=1 | Conf_mask=5 |
    | - | - | - |
    | R3 | 7920ns | 7610ns |
    | R4 | 7440ns | 6880ns |
