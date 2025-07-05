# Week 1 #

## 6/29 ##

**对寄存器重命名的初步理解:**

- RAT-RS-ROB-ARF 数据复制:

> __RAT__: 32个寄存器条目, 每条为: `valid`, `tag`, `data`. <br>
> __RS__: 若干个指令条目, 每条为: 确认指令有效的`valid_op`, `ra&rb`的两个`valid`, `tag`, `data`, `ROB`为指令分配的`tag_ROB`. <br>
> __ROB__: 若干行空间, 每行为: `valid_Result`, `rw`, `RegWr`, `Result`. <br>

> __cc1__: 取指. <br>
> __cc2__: 译码. <br>
> __cc3__: (1) 在`RAT`内读取`ra`, `rb`的`valid`, `tag`与`data`; <br>
&emsp;&emsp;(2) 收到`ROB`分配给它的`tag_ROB`, 将`RAT`内`rw`的标签写为`tag_ROB`; <br>
&emsp;&emsp;(3) 将`rw`提前写入`ROB`中对应的`tag_ROB`条目. <br>
> __cc4__: 根据指令类型, 将`valid`, `tag`, `data`, `tag_ROB`写入对应的`RS`. <br>
> __cc?__: 等待执行完指令的广播信号, 遍历`RS`将`tag`与广播信号的`tag_ROB`相同的`valid`全置1, `data`修改为`Result`. <br>
> __cc5__: 发现源寄存器`valid`均为1, 可发射. <br>
> __cc6__: 执行. <br>
> __cc7__: (1) 将`Result`写入`ROB`的`tag_ROB`条目; <br>
&emsp;&emsp;(2) 将执行结果`Result`和`tag_ROB`广播, 遍历`RAT`, 若有寄存器的`tag`相同, 则写入`Result`并置`valid`为1; <br>
&emsp;&emsp;(3) 遍历`RS`, 若`tag`相同则作前述写入. <br>
> __cc8__: `ROB`作为`FIFO`每次吐出若干行, 根据`rw`, 将`Result`写入最后端的`ARF`对应条目. <br>
> __cc?__: 若分支预测错误或其他东西在`ROB`吐出的行中出现, 则清空流水线各级, `RS`, `RAT`所有`tag`和`valid`, `ROB`后续所有东西, 将`ARF`所有备份数据复制到`RAT`中. <br>

- RAT-RS-ROB-ARF 仅索引, PRF 集中存储:

> __cc1__: 取指. <br>
> __cc2__: 译码. <br>
> __cc3__: (1) 在`RAT`内读取`ra`, `rb`的`valid`和`tag`; <br>
&emsp;&emsp;(2) 收到`PRF`分配给它的可用寄存器的`tag_PRF`, 将`RAT`内`rw`的标签写为`tag_PRF`; <br>
&emsp;&emsp;(3) 收到`tag_ROB`, 将`rw`, `tag_PRF`写入`ROB`对应条目; <br>
&emsp;&emsp;(4) 在`PRF`中置`tag_PRF`寄存器为不可用. <br>
> __cc4__: 根据指令类型, 将`valid`, `tag`, `tag_PRF`, `tag_ROB`写入对应的`RS`. <br>
> __cc?__: 等待广播信号, 若广播的`tag_PRF`与`tag`相同, 则置其`valid`为1. <br>
> __cc5__: 两个源寄存器的`valid`均为1, 发射. <br>
> __cc6__: 访问`PRF`, 根据两个`tag`读取`data`. <br>
> __cc7__: 执行. <br>
> __cc8__: (1) 执行结果`Result`写入`PRF`的`tag_PRF`号寄存器, 并置其为可用; <br>
&emsp;&emsp;(2) 广播`tag_PRF`给`RAT`, `RS`, 修改所有相同标签的条目的`valid`为1; <br>
&emsp;&emsp;(3) 将`ROB`的`tag_ROB`条目的`valid`置为有效. <br>
> __cc9__: 有效的`ROB`条目被依次发射, 在`ARF`的`rw`条目修改索引为`tag_PRF`. <br>
> __cc?__: 若出现异常, 则清空其余所有信息, 保留`PRF`数据, 复制`ARF`索引到`RAT`. <br>

## 6/30 ##

**PRF寄存器重命名&精确异常恢复:**

- 本质为PRF寄存器资源的分配与释放.

- __分配__:

> - 用`free_list`记录各寄存器是否可用, 根据优先级选择一个寄存器`P_new`, 将编号传给`RAT`并写入, 即可将`Rw`映射到`P_new`; <br>
> - 此时`RAT`会弹出原先`Rw`对应的`P_old`, 将`P_old`, `P_new`存到`ROB`条目中; <br>
> - 并在`free_list`中设置`P_new`为不可用. <br>

- __释放__:

> - `ROB`一条一条弹出条目, 若无异常, 则`P_new`写入`ARF`中, 并将`P_old`对应寄存器释放, 即在`free_list`中设置`P_old`可用; <br>
> - 若出现异常, 则清空`ROB`, `P_old`回滚为`Rw`所映射的位置. <br>

- 关键: `I1`, `I2`均要写入`R1`, 分别分配了`P1`, `P2`, 则`P1`必须在`I2`退休的时候才能释放;

- 否则: `I2`覆盖`I1`时将`P1`提前释放, `I2`后续指令可能被分配到`P1`, 造成`P1`数据污染, 但`I2`可能是异常后的指令, `P1`不应该释放.

- 结构实现:

> __free_list__: (可内置于`PRF`或`RAT`,) 输出`P_new`, 输入来自`ROB`的`P_old`, <br>
> 若指令有效发射则置`free_list[P_new]=0`, 若`ROB`退休则置`free_list[P_old]=1`. <br>
> __ROB__: `指令发射有效位` + `RegWr有效位` + `Rw` + `P_new`(二者写入`ARF`) + `P_old`(新人确认真能接班了, 老人才能退休). <br>
> __RS__: `Ra&Rb`查`RAT`查出的`tagRa&tagRb`, `validRa&validRb` + `ROB`分配的条目索引`tag_ROB`(后面写入这个条目) + `PRF`分配给`Rw`的`tag_PRF`(`P_new`) + `指令发射有效位`. <br>
> __RAT__: 简单的`validRegs`和`tagRegs`. <br>

*跑通了乱序单发射原型机**ELEC_core_v1**.*

## 7/1 ##

*验证了原型机的内部控制不完备, 无法精确处理**RS, PRF, ROB满**的情况.*

- 使用独立的`CTRL`单元, 生成前后端各自的`freeze_front`, `freeze_back`以及`valid_issue`信号.

*已修复**ELEC_core_v1**.*

## 7/2 ##

*先定端口连接, 再写内部逻辑的**自顶向下**设计方法.*

## 7/3 ##

*乱序多发射(3-2-3)原型机**ELEC_core_v2**跑通.*

- 修正了几个误区: 
    - `ROB`或`PRF`满时, **只能冻结前端, 不能冻结后端**, 否则会出现永远停滞的状态, 且由于**前端分配条目, 后端补充数据**, 后端应该是没有冻结的必要的;
    - 若并行3条指令, 查`sRAT`时要考虑**I1`R_dst`对I2/I3`R_src`的覆盖, I2`R_dst`对I3`R_src`的覆盖**, 代码实现上是引入**if嵌套**的分支旁路;
    - 若3条指令同时提交, 则异常出现的指令后的指令不能写入`aRAT`, 不能3端口简单的一一对接, 代码实现需要类似上面的**if嵌套**.

## 7/5 ##

**内存读写(3-3-3)原型机*ELEC_core_v3*的初步设想:**

- **DECODER**:
    - 访存指令译为`lw Rw, Ra(Imm)`(Rb=0), `sw Rb, Ra(Imm)`(不修改sRAT内的Rw-Pw映射).

- **RS_AGU**:
    - 正常的乱序发射队列, 编号为`tag_Addr`, 条目为`valid_op|Pa|valid_Ra|Imm`.
    - 在**RENAME**阶段, 为三条指令提供三个空闲的`tag_Addr`位置, 依次判断: 若`Type=load/save`, 则写入`valid_op=1`,`Pa`,`valid_Ra`,`Imm`. 且`tag_Addr`同时送至**LSQ**.
    - 根据设定的唤醒逻辑, 发射`valid_op=1`,`valid_Ra=1`的条目, 输出`valid_op`,`tag_Addr`,`Pa`,`Imm`.
    - 在**READ**阶段, 在**PRF**内读`Pa`得`busA`; 在**EX**阶段, 在**AGU**内计算`Addr=busA+SignExt(Imm)`.
    - 将执行结果的`valid_op`,`tag_Addr`,`Addr`仅广播给**LSQ**.

- **LSQ**:
    - 半乱序发射队列, 在`ptr_young`顺序写入, 在`ptr_old`半乱序读出, 即:
        - `ptr_old`条目为**load**, 则允许乱序发射**此load到第一个save(不含)之间的所有load**;
        - `ptr_old`条目为**save**, 则只允许发射**此save**.
    - 条目为`valid_op|mode|Px|valid_Rx|tag_Addr|Addr|valid_Addr`.
    - 在**RENAME**阶段:
        - 若`Type=load`, 则写入`valid_op=1`,`mode=load`,`Px=Pw`,`valid_Rx=1`,`tag_Addr=tag_Addr_{RS_AGU提供}`,`valid_Addr=0`;
        - 若`Type=save`, 则写入`valid_op=1`,`mode=save`,`Px=Pb`,`valid_Rx=valid_Rb`,`tag_Addr`,`valid_Addr=0`.
    - 接收来自**FU**的广播, 对应`Px`置`valid_Rx=1`; 接收来自**AGU**的广播, 对应`tag_Addr`置`valid_Addr=1`,`Addr=Addr_{AGU计算结果}`.
    - 准备好的标志为`valid_op=1`,`valid_Rx=1`,`valid_Addr=1`.
    - 根据半乱序发射的唤醒逻辑, 发射`valid_op`,`mode`,`Px`,`Addr`.
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
