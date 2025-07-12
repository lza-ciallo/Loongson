# ALU架构总结

### **整体**

基于arch2=3-2-3多发射原型机，尝试设计：

- 分支预测，
- 基于Architecture State方法的重命名和恢复，
- 分布式、非数据捕捉的乱序发射，
- ADD、MUL双FU执行，
- 提交与退休

### 具体设计

**IF**

![1752314387631](image/summary=arch5_ALU/1752314387631.png)

IF阶段（参考lza, wyc的设计），使用Gshare技术进行Branch Predict

- 每cc： `PC`输出 `pc`值，并行进行 `INST_MEM `(后续要改为 `INST_CACHE`) 访问，`GSHARE_BRANCH_PREDICTOR`预测

  - `INST_MEM`每cc取 `pc`及邻居，共**3**条指令
  - `GSHARE_BRANCH_PREDICTOR`每cc给出预测 `pc_predict`及其有效性 `predict`
- 预测器维护

  - ID执行后，确认的分支指令信息可对核心数据 `BTB` 做更新
  - EX执行后，`BRU`确认分支逻辑，`branch`信号，对核心状态机 , `PHT`, `FIFO`更新
- PC值更新

  - 按优先级，从状态回滚 `pc_unsel`, 无条件跳转 `pc_jump`, 当前cc所得预测 `pc_predict`, 和默认步长更新 `pc_default`中激情四择

TODO: 

- `PCADD`指令要在IF阶段完成
- `INST_CACHE`需要实现
- `INST_CACHE`对含分支指令的指令块长度需要规划

**ID**

![1752315250573](image/summary=arch5_ALU/1752315250573.png)

ID阶段平凡地解码，当前产生信号还需要较大改动


**RENAME**

![1752315552337](image/summary=arch5_ALU/1752315552337.png)

RENAME采用了Architecture State方法，也即同时维护 `sRAT`(speculative reorder alias table), 和aRAT(architecture reorder alias table)，实现了类似于“双指针”般的效果

```plaintext
                aRAT                    sRAT
             aFreelist              sFreelist
               ↓                       ↓
 ┌────┬────┬────┬─────── ... ───────┬────┬────┐
 │    │    │    │                   │    │    │
 └────┴────┴────┴─────── ... ───────┴────┴────┘
               ↑                       ↑
           确认正确的（已commit）    speculative（投机态）
 ─────────────────────────────────────────────→ Static Space
```

TODO

- 控制信号还要再精细化一下
