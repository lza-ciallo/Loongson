*跑通访存原型机**ELEC_core_v3**的行为级仿真.*

*但其中**LSQ**的**半乱序唤醒逻辑**, **DATA_MEM**的**FIFO搜索最近一次地址匹配的输入**当前使用了疑似不可综合的类C写法, 需要修改实现方法才能综合.*

- 修正: 
    - **AGU**和**LSQ**传递`Addr`, 不使用**AGU**分配的`tag_Addr`作为确认标志, 因为可能两条相邻访存指令在**RS_AGU**中使用同一条目;
    - 改为使用与其余发射队列统一的`tag_ROB`作为确认标志.

- docx文档中为Gemini对于LSQ唤醒逻辑实现方法的修改意见, 说不定后面会用到.

*以上为最新说明.*
---

*截取自开发日志*

- **DECODER**:
    - 访存指令译为`lw Rw, Ra(Imm)`(Rb=0), `sw Rb, Ra(Imm)`(不修改sRAT内的Rw-Pw映射).

- **RS_AGU**:
    - 正常的乱序发射队列, 编号为`tag_Addr`, 条目为`valid_op|Pa|valid_Pa|Imm`.
    - 在**RENAME**阶段, 为三条指令提供三个空闲的`tag_Addr`位置, 依次判断: 若`Type=load/save`, 则写入`valid_op=1`,`Pa`,`valid_Pa`,`Imm`. 且`tag_Addr`同时送至**LSQ**.
    - 根据设定的唤醒逻辑, 发射`valid_op=1`,`valid_Pa=1`的条目, 输出`valid_op`,`tag_Addr`,`Pa`,`Imm`.
    - 在**READ**阶段, 在**PRF**内读`Pa`得`busA`; 在**EX**阶段, 在**AGU**内计算`Addr=busA+SignExt(Imm)`.
    - 将执行结果的`valid_op`,`tag_Addr`,`Addr`仅广播给**LSQ**.

- **LSQ**:
    - 半乱序发射队列, 在`ptr_young`顺序写入, 在`ptr_old`半乱序读出, 即:
        - `ptr_old`条目为**load**, 则允许乱序发射**此load到第一个save(不含)之间的所有load**;
        - `ptr_old`条目为**save**, 则只允许发射**此save**.
    - 条目为`valid_op|mode|Px|valid_Px|tag_Addr|Addr|valid_Addr|tag_ROB`.
    - 在**RENAME**阶段:
        - 若`Type=load`, 则写入`valid_op=1`,`mode=load`,`Px=Pw`,`valid_Px=1`,`tag_Addr=tag_Addr_{RS_AGU提供}`,`valid_Addr=0`,`tag_ROB`;
        - 若`Type=save`, 则写入`valid_op=1`,`mode=save`,`Px=Pb`,`valid_Px=valid_Rb`,`tag_Addr`,`valid_Addr=0`,`tag_ROB`.
    - 接收来自**FU**的广播, 对应`Px`置`valid_Px=1`; 接收来自**AGU**的广播, 对应`tag_Addr`置`valid_Addr=1`,`Addr=Addr_{AGU计算结果}`.
    - 准备好的标志为`valid_op=1`,`valid_Px=1`,`valid_Addr=1`.
    - 根据半乱序发射的唤醒逻辑, 发射`valid_op`,`mode`,`Px`,`Addr`,`tag_ROB`.
    - 执行阶段:
        - 若`mode=load`:
            - 在**READ**阶段不干活;
            - 在**EX**阶段读出`out_data=MEM[Addr]`;
            - 在**ROB**阶段写入ROB, 写入PRF`PRF[Px]=out_data`, 并广播`valid_op`,`mode`,`Px`;
            - 退休时置`free_list[Pw_old]=1`, 同ALU指令.
        - 若`mode=save`:
            - 在**READ**阶段读`in_data=PRF[Px]`;
            - 在**EX**阶段将`in_data|Addr`写入**FIFO**;
            - 在**ROB**阶段仅写入ROB, 广播总线各接收端默认`mode=save`无效;
            - 退休时将**FIFO**送一条写入**MEM**.

- **FIFO**:
    - 条目为`in_data|Addr`, 内部维护`ptr_old`,`ptr_young`(不是**LSQ**的), 以实现压缩式存储.
    - 配合**save**使用, **EX**阶段写入`FIFO[ptr_young]`, 退休时读出`FIFO[ptr_old]`.
