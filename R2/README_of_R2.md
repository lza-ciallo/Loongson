- <u>*<inst_fetch, commit_unit>*</u> IFIFO: 64->32, ROB: 128->64, 为此修改 tag_rob & ptr_old: [6:0]->[5:0].

- <u>*<back_end>*</u> 删去统一的 EX-CDB 级间寄存器, 改为各 FU 内嵌的输出寄存器.
