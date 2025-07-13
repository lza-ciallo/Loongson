# core_r1 #

## 7/13 ##

*整理了基础指令集, 后续据此实现**core_r1**版本.*

### 基础指令 (57-8=49) ###

- ALU (20):

    | add | sub | slt | sltu | and | or | nor | xor | sll | srl | sra |
    | - | - | - | - | - | - | - | - | - | - | - |
    |addi | - | slti | sltui | andi | ori | - | xori | slli | srli | srai |

- M/D (7):

    | mul | mulh | div | mod |
    | - | - | - | - |
    | - | mulhu | divu | modu |

- AGU, L/S (8):

    | ldb | ldh | ldw | ldbu | ldhu |
    | - | - | - | - | - |
    | stb | sth | stw | - | - |

- BRU (6):

    | beq | bne | blt | bge |
    | - | - | - | - |
    | - | - | bltu | bgeu |

- 直通 (4):

    | lu12i | bl |
    | - | - |
    | pcaddu12i | jirl |

- JIRL (-)

- 特殊处理 (4):
    
    nop `发射addi r0,r0,r0`, B `发射nop`, dbar `仅发至L/S`, ibar `ROB预写入即完成`

| # | 指令 | 伪代码 | 发射队列 |
| - | - | - | - |
| 1 | add.w rd, rj, rk | GR[rd] = GR[rj] + GR[rk] | ALU |
| 2 | sub.w rd, rj, rk | GR[rd] = GR[rj] - GR[rk] | ALU |
| 3 | addi.w rd, rj, si12 | GR[rd] = GR[rj] + SignExt(si12) | ALU |
| 4 | lu12i.w rd, si20 | GR[rd] = {si20, 12'b0} | 直通 |
| 5 | slt rd, rj, rk | GR[rd] = (signed(GR[rj]) < signed(GR[rk]))? 1 : 0 | ALU |
| 6 | sltu rd, rj, rk | GR[rd] = (unsigned(GR[rj]) < unsigned(GR[rk]))? 1 : 0 | ALU |
| 7 | slti rd, rj, si12 | GR[rd] = (signed(GR[rj]) < signed(SignExt(si12)))? 1 : 0 | ALU |
| 8 | sltui rd, rj, si12 | GR[rd] = (unsigned(GR[rj]) < unsigned(SignExt(si12)))? 1 : 0 | ALU |
| 9 | pcaddu12i rd, si20 | GR[rd] = PC + {si20, 12'b0} | 直通 |
| 10 | and rd, rj, rk | GR[rd] = GR[rj] & GR[rk] | ALU |
| 11 | or rd, rj, rk | GR[rd] = GR[rj] \| GR[rk] | ALU |
| 12 | nor rd, rj, rk | GR[rd] = ~(GR[rj] \| GR[rk]) | ALU |
| 13 | xor rd, rj, rk | GR[rd] = GR[rj] ^ GR[rk] | ALU |
| 14 | andi rd, rj, ui12 | GR[rd] = GR[rj] & ZeroExt(ui12) | ALU |
| 15 | ori rd, rj, ui12 | GR[rd] = GR[rj] \| ZeroExt(ui12) | ALU |
| 16 | xori rd, rj, ui12 | GR[rd] = GR[rj] ^ ZeroExt(ui12) | ALU |
| 17 | nop | -  | ALU |
| 18 | mul.w rd, rj, rk | GR[rd] = signed(GR[rj]) * signed(GR[rk])[31:0] | M/D |
| 19 | mulh.w rd, rj, rk | GR[rd] = signed(GR[rj]) * signed(GR[rk])[63:32] | M/D |
| 20 | mulh.wu rd, rj, rk | GR[rd] = unsigned(GR[rj]) * unsigned(GR[rk])[63:32] | M/D |
| 21 | div.w rd, rj, rk | GR[rd] = signed(GR[rj]) / signed(GR[rk])[31:0] | M/D |
| 22 | div.wu rd, rj, rk | GR[rd] = unsigned(GR[rj]) / unsigned(GR[rk])[31:0] | M/D |
| 23 | mod.w rd, rj, rk | GR[rd] = signed(GR[rj]) % signed(GR[rk])[31:0] | M/D |
| 24 | mod.wu rd, rj, rk | GR[rd] = unsigned(GR[rj]) % unsigned(GR[rk])[31:0] | M/D |
| 25 | sll.w rd, rj, rk | GR[rd] = GR[rj] << GR[rk][4:0] | ALU |
| 26 | srl.w rd, rj, rk | GR[rd] = GR[rj] >> GR[rk][4:0] | ALU |
| 27 | sra.w rd, rj, rk | GR[rd] = GR[rj] >>> GR[rk][4:0] | ALU |
| 28 | slli.w rd, rj, ui5 | GR[rd] = GR[rj] << ui5 | ALU |
| 29 | srli.w rd, rj, ui5 | GR[rd] = GR[rj] >> ui5 | ALU |
| 30 | srai.w rd, rj, ui5 | GR[rd] = GR[rj] >>> ui5 | ALU |
| 31 | beq rj, rd, offs16 | if GR[rj] == GR[rd]: PC = PC + SignExt({offs16, 2'b0}) | BRU |
| 32 | bne rj, rd, offs16 | if GR[rj] != GR[rd]: PC = PC + SignExt({offs16, 2'b0}) | BRU |
| 33 | blt rj, rd, offs16 | if signed(GR[rj]) < signed(GR[rd]): PC = PC + SignExt({offs16, 2'b0}) | BRU |
| 34 | bge rj, rd, offs16 | if signed(GR[rj]) >= signed(GR[rd]): PC = PC + SignExt({offs16, 2'b0}) | BRU |
| 35 | bltu rj, rd, offs16 | if unsigned(GR[rj]) < unsigned(GR[rd]): PC = PC + SignExt({offs16, 2'b0}) | BRU |
| 36 | bgeu rj, rd, offs16 | if unsigned(GR[rj]) >= unsigned(GR[rd]): PC = PC + SignExt({offs16, 2'b0}) | BRU |
| 37 | b offs26 | PC = PC + SignExt({offs26, 2'b0}) | ALU (向后传nop) |
| 38 | bl offs26 | GR[1] = PC + 4, PC = PC + SignExt({offs26, 2'b0}) | 直通 |
| 39 | jirl rd, rj, offs16 | GR[rd] = PC + 4, PC = GR[rj] + SignExt({offs16, 2'b0}) | 直通; JIRL |
| 40 | ld.b rd, rj, si12 | addr = GR[rj] + SignExt(si12), GR[rd] = SignExt(MEM(addr, BYTE)) | AGU; L/S |
| 41 | ld.h rd, rj, si12 | addr = GR[rj] + SignExt(si12), GR[rd] = SignExt(MEM(addr, HALFWORD)) | AGU; L/S |
| 42 | ld.w rd, rj, si12 | addr = GR[rj] + SignExt(si12), GR[rd] = MEM(addr, WORD) | AGU; L/S |
| 43 | ld.bu rd, rj, si12 | addr = GR[rj] + SignExt(si12), GR[rd] = ZeroExt(MEM(addr, BYTE)) | AGU; L/S |
| 44 | ld.hu rd, rj, si12 | addr = GR[rj] + SignExt(si12), GR[rd] = ZeroExt(MEM(addr, HALFWORD)) | AGU; L/S |
| 45 | st.b rd, rj, si12 | addr = GR[rj] + SignExt(si12), MEM(addr, BYTE) = GR[rd][7:0] | AGU; L/S |
| 46 | st.h rd, rj, si12 | addr = GR[rj] + SignExt(si12), MEM(addr, HALFWORD) = GR[rd][7:0] | AGU; L/S |
| 47 | st.w rd, rj, si12 | addr = GR[rj] + SignExt(si12), MEM(addr, WORD) = GR[rd][7:0] | AGU; L/S |
| 48 | preld hint rj, si12 | addr = GR[rj] + SignExt(si12), - | (x) |
| 49 | ll.w rd, rj, si14 | ? | ?(x) |
| 50 | sc.w rd, rj, si14 | ? | ?(x) |
| 51 | dbar hint=0 | 限制 LSQ 半乱序发射 | L/S |
| 52 | ibar hint=0 | IBAR 提交前一直 stall | 不占位 |
| 53 | syscall code | - | (x) |
| 54 | break code | - | (x) |
| 55 | rdcntvl.w rd | GR[rd] = Counter[31:0] | 直通(x) |
| 56 | rdcntvh.w rd | GR[rd] = Counter[63:32] | 直通(x) |
| 57 | rdcntid rj | GR[rj] = Counter ID | 直通(x) |