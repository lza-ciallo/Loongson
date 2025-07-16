# LoongArch compiler test program
.text
.global _start

_start:
    # 简单的加法运算
    addi.w $r4, $r0, 10    # r4 = 10
    addi.w $r5, $r0, 20    # r5 = 20
    add.w  $r6, $r4, $r5   # r6 = r4 + r5 = 30
    
    # 系统调用退出
    addi.w $r4, $r0, 0     # 退出码 0
    addi.w $r11, $r0, 93   # sys_exit 系统调用号
    syscall 0              # 执行系统调用
