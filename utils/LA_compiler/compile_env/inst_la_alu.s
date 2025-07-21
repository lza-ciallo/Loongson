# LoongArch32r
# ALU test program

.text
.global _start

_start:
    # # 初始化寄存器值
    # ori $r0, $r0, 0        # R0 = 0
    # ori $r2, $r0, 2        # R2 = 2  
    # ori $r3, $r0, 3        # R3 = 3
    # ori $r4, $r0, 4        # R4 = 4
    # ori $r6, $r0, 6        # R6 = 6

    # 第一组计算
    add.w $r1, $r0, $r4    # R1=0+4=4          
    mul.w $r1, $r2, $r3    # R1=2*3=6          
    mul.w $r1, $r1, $r1    # R1=6*6=36         
    add.w $r5, $r1, $r4    # R5=36+4=40        
    add.w $r7, $r2, $r6    # R7=2+6=8          
    mul.w $r2, $r2, $r6    # R2=2*6=12         
    add.w $r6, $r3, $r4    # R6=3+4=7          
    mul.w $r7, $r7, $r6    # R7=8*7=56         
    add.w $r5, $r5, $r7    # R5=40+56=96       
    mul.w $r3, $r7, $r3    # R3=56*3=168       

    # 第二组计算
    add.w $r1, $r0, $r6    # R1=0+7=7          
    add.w $r3, $r0, $r4    # R3=0+4=4          
    mul.w $r1, $r3, $r3    # R1=4*4=16         
    mul.w $r1, $r1, $r1    # R1=16*16=256      
    add.w $r5, $r1, $r4    # R5=256+4=260      
    add.w $r7, $r2, $r6    # R7=12+7=19        
    mul.w $r2, $r2, $r6    # R2=12*7=84        
    add.w $r6, $r3, $r4    # R6=4+4=8          
    mul.w $r7, $r7, $r6    # R7=19*8=152       
    add.w $r5, $r5, $r7    # R5=260+152=412    
    mul.w $r3, $r7, $r3    # R3=152*4=608      

    # 结束
    add.w $r0, $r0, $r0    # STOP              
    add.w $r1, $r1, $r1    # $neglect!
    add.w $r2, $r1, $r1
    add.w $r3, $r1, $r1
    add.w $r4, $r1, $r1
    


    # # 系统调用退出程序
    # ori $a7, $r0, 93       # 系统调用号 93 (exit)
    # ori $a0, $r0, 0        # 退出状态码 0
    # syscall

# res
# R0: 0
# R1: 256
# R2: 84
# R3: 608
# R4: 4
# R5: 412
# R6: 8
# R7: 152