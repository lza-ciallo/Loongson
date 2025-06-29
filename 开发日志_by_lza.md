# 6/29 #

对**寄存器重命名**的初步理解:

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