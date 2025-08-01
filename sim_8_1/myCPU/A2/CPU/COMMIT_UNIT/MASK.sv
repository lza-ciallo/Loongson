`include "../defs.svh"

module MASK (
    input                   Conf,
    input       [4 : 0]     ready_vec,
    input       [4 : 0]     isBranch_vec,
    input       [4 : 0]     isStore_vec,
    input       [4 : 0]     isExcp_vec,
    input       [4 : 0]     csrWr_vec,
    input       [4 : 0]     isErtn_vec,
    input       [4 : 0]     isIdle_vec,
    output  reg [4 : 0]     ready_mask,
    output  reg [2 : 0]     Branch_num,
    output  reg             find_Branch,
    output  reg             find_Store,
    output  reg             find_Excp,
    output  reg             find_csrWr,
    output  reg             find_Ertn,
    output  reg             find_Idle
);

    reg         [4 : 0]     ready_temp_store;
    reg         [4 : 0]     ready_temp_branch;
    reg         [4 : 0]     ready_temp_excp;
    reg         [4 : 0]     ready_temp_csrWr;
    reg         [4 : 0]     ready_temp_ertn;
    reg         [4 : 0]     ready_temp_idle;

    reg         [2 : 0]     store_num;
    reg         [2 : 0]     csrWr_num;
    reg         [2 : 0]     ertn_num;

    always @(*) begin
        if (!Conf) begin
            
            // store 贪到第二条前
            casez ({ready_vec, isStore_vec})
                10'b00000_?????:    begin   ready_temp_store    =   5'b00000;   store_num   =   7;  end

                10'b00001_????0:    begin   ready_temp_store    =   5'b00001;   store_num   =   7;  end
                10'b00001_????1:    begin   ready_temp_store    =   5'b00001;   store_num   =   0;  end

                10'b00011_???00:    begin   ready_temp_store    =   5'b00011;   store_num   =   7;  end
                10'b00011_???01:    begin   ready_temp_store    =   5'b00011;   store_num   =   0;  end
                10'b00011_???10:    begin   ready_temp_store    =   5'b00011;   store_num   =   1;  end
                10'b00011_???11:    begin   ready_temp_store    =   5'b00001;   store_num   =   0;  end

                10'b00111_??000:    begin   ready_temp_store    =   5'b00111;   store_num   =   7;  end
                10'b00111_??001:    begin   ready_temp_store    =   5'b00111;   store_num   =   0;  end
                10'b00111_??010:    begin   ready_temp_store    =   5'b00111;   store_num   =   1;  end
                10'b00111_??100:    begin   ready_temp_store    =   5'b00111;   store_num   =   2;  end
                10'b00111_???11:    begin   ready_temp_store    =   5'b00001;   store_num   =   0;  end
                10'b00111_??101:    begin   ready_temp_store    =   5'b00011;   store_num   =   0;  end
                10'b00111_??110:    begin   ready_temp_store    =   5'b00011;   store_num   =   1;  end

                10'b01111_?0000:    begin   ready_temp_store    =   5'b01111;   store_num   =   7;  end
                10'b01111_?0001:    begin   ready_temp_store    =   5'b01111;   store_num   =   0;  end
                10'b01111_?0010:    begin   ready_temp_store    =   5'b01111;   store_num   =   1;  end
                10'b01111_?0100:    begin   ready_temp_store    =   5'b01111;   store_num   =   2;  end
                10'b01111_?1000:    begin   ready_temp_store    =   5'b01111;   store_num   =   3;  end
                10'b01111_???11:    begin   ready_temp_store    =   5'b00001;   store_num   =   0;  end
                10'b01111_??101:    begin   ready_temp_store    =   5'b00011;   store_num   =   0;  end
                10'b01111_?1001:    begin   ready_temp_store    =   5'b00111;   store_num   =   0;  end
                10'b01111_??110:    begin   ready_temp_store    =   5'b00011;   store_num   =   1;  end
                10'b01111_?1010:    begin   ready_temp_store    =   5'b00111;   store_num   =   1;  end
                10'b01111_?1100:    begin   ready_temp_store    =   5'b00111;   store_num   =   2;  end

                10'b11111_00000:    begin   ready_temp_store    =   5'b11111;   store_num   =   7;  end
                10'b11111_00001:    begin   ready_temp_store    =   5'b11111;   store_num   =   0;  end
                10'b11111_00010:    begin   ready_temp_store    =   5'b11111;   store_num   =   1;  end
                10'b11111_00100:    begin   ready_temp_store    =   5'b11111;   store_num   =   2;  end
                10'b11111_01000:    begin   ready_temp_store    =   5'b11111;   store_num   =   3;  end
                10'b11111_10000:    begin   ready_temp_store    =   5'b11111;   store_num   =   4;  end
                10'b11111_???11:    begin   ready_temp_store    =   5'b00001;   store_num   =   0;  end
                10'b11111_??101:    begin   ready_temp_store    =   5'b00011;   store_num   =   0;  end
                10'b11111_?1001:    begin   ready_temp_store    =   5'b00111;   store_num   =   0;  end
                10'b11111_10001:    begin   ready_temp_store    =   5'b01111;   store_num   =   0;  end
                10'b11111_??110:    begin   ready_temp_store    =   5'b00011;   store_num   =   1;  end
                10'b11111_?1010:    begin   ready_temp_store    =   5'b00111;   store_num   =   1;  end
                10'b11111_10010:    begin   ready_temp_store    =   5'b01111;   store_num   =   1;  end
                10'b11111_?1100:    begin   ready_temp_store    =   5'b00111;   store_num   =   2;  end
                10'b11111_10100:    begin   ready_temp_store    =   5'b01111;   store_num   =   2;  end
                10'b11111_11000:    begin   ready_temp_store    =   5'b01111;   store_num   =   3;  end

                default:            begin   ready_temp_store    =   5'b00000;   store_num   =   7;  end
            endcase

            // branch 保守找第一条
            casez ({ready_vec, isBranch_vec})
                10'b00000_?????:    begin   ready_temp_branch   =   5'b00000;   Branch_num  =   7;  end

                10'b00001_????0:    begin   ready_temp_branch   =   5'b00001;   Branch_num  =   7;  end
                10'b00001_????1:    begin   ready_temp_branch   =   5'b00001;   Branch_num  =   0;  end

                10'b00011_???00:    begin   ready_temp_branch   =   5'b00011;   Branch_num  =   7;  end
                10'b00011_????1:    begin   ready_temp_branch   =   5'b00001;   Branch_num  =   0;  end
                10'b00011_???10:    begin   ready_temp_branch   =   5'b00011;   Branch_num  =   1;  end

                10'b00111_??000:    begin   ready_temp_branch   =   5'b00111;   Branch_num  =   7;  end
                10'b00111_????1:    begin   ready_temp_branch   =   5'b00001;   Branch_num  =   0;  end
                10'b00111_???10:    begin   ready_temp_branch   =   5'b00011;   Branch_num  =   1;  end
                10'b00111_??100:    begin   ready_temp_branch   =   5'b00111;   Branch_num  =   2;  end

                10'b01111_?0000:    begin   ready_temp_branch   =   5'b01111;   Branch_num  =   7;  end
                10'b01111_????1:    begin   ready_temp_branch   =   5'b00001;   Branch_num  =   0;  end
                10'b01111_???10:    begin   ready_temp_branch   =   5'b00011;   Branch_num  =   1;  end
                10'b01111_??100:    begin   ready_temp_branch   =   5'b00111;   Branch_num  =   2;  end
                10'b01111_?1000:    begin   ready_temp_branch   =   5'b01111;   Branch_num  =   3;  end

                10'b11111_00000:    begin   ready_temp_branch   =   5'b11111;   Branch_num  =   7;  end
                10'b11111_????1:    begin   ready_temp_branch   =   5'b00001;   Branch_num  =   0;  end
                10'b11111_???10:    begin   ready_temp_branch   =   5'b00011;   Branch_num  =   1;  end
                10'b11111_??100:    begin   ready_temp_branch   =   5'b00111;   Branch_num  =   2;  end
                10'b11111_?1000:    begin   ready_temp_branch   =   5'b01111;   Branch_num  =   3;  end
                10'b11111_10000:    begin   ready_temp_branch   =   5'b11111;   Branch_num  =   4;  end

                default:            begin   ready_temp_branch   =   5'b00000;   Branch_num  =   7;  end
            endcase

            // csrWr 与 store 一样贪
            casez ({ready_vec, csrWr_vec})
                10'b00000_?????:    begin   ready_temp_csrWr    =   5'b00000;   csrWr_num   =   7;  end

                10'b00001_????0:    begin   ready_temp_csrWr    =   5'b00001;   csrWr_num   =   7;  end
                10'b00001_????1:    begin   ready_temp_csrWr    =   5'b00001;   csrWr_num   =   0;  end

                10'b00011_???00:    begin   ready_temp_csrWr    =   5'b00011;   csrWr_num   =   7;  end
                10'b00011_???01:    begin   ready_temp_csrWr    =   5'b00011;   csrWr_num   =   0;  end
                10'b00011_???10:    begin   ready_temp_csrWr    =   5'b00011;   csrWr_num   =   1;  end
                10'b00011_???11:    begin   ready_temp_csrWr    =   5'b00001;   csrWr_num   =   0;  end

                10'b00111_??000:    begin   ready_temp_csrWr    =   5'b00111;   csrWr_num   =   7;  end
                10'b00111_??001:    begin   ready_temp_csrWr    =   5'b00111;   csrWr_num   =   0;  end
                10'b00111_??010:    begin   ready_temp_csrWr    =   5'b00111;   csrWr_num   =   1;  end
                10'b00111_??100:    begin   ready_temp_csrWr    =   5'b00111;   csrWr_num   =   2;  end
                10'b00111_???11:    begin   ready_temp_csrWr    =   5'b00001;   csrWr_num   =   0;  end
                10'b00111_??101:    begin   ready_temp_csrWr    =   5'b00011;   csrWr_num   =   0;  end
                10'b00111_??110:    begin   ready_temp_csrWr    =   5'b00011;   csrWr_num   =   1;  end

                10'b01111_?0000:    begin   ready_temp_csrWr    =   5'b01111;   csrWr_num   =   7;  end
                10'b01111_?0001:    begin   ready_temp_csrWr    =   5'b01111;   csrWr_num   =   0;  end
                10'b01111_?0010:    begin   ready_temp_csrWr    =   5'b01111;   csrWr_num   =   1;  end
                10'b01111_?0100:    begin   ready_temp_csrWr    =   5'b01111;   csrWr_num   =   2;  end
                10'b01111_?1000:    begin   ready_temp_csrWr    =   5'b01111;   csrWr_num   =   3;  end
                10'b01111_???11:    begin   ready_temp_csrWr    =   5'b00001;   csrWr_num   =   0;  end
                10'b01111_??101:    begin   ready_temp_csrWr    =   5'b00011;   csrWr_num   =   0;  end
                10'b01111_?1001:    begin   ready_temp_csrWr    =   5'b00111;   csrWr_num   =   0;  end
                10'b01111_??110:    begin   ready_temp_csrWr    =   5'b00011;   csrWr_num   =   1;  end
                10'b01111_?1010:    begin   ready_temp_csrWr    =   5'b00111;   csrWr_num   =   1;  end
                10'b01111_?1100:    begin   ready_temp_csrWr    =   5'b00111;   csrWr_num   =   2;  end

                10'b11111_00000:    begin   ready_temp_csrWr    =   5'b11111;   csrWr_num   =   7;  end
                10'b11111_00001:    begin   ready_temp_csrWr    =   5'b11111;   csrWr_num   =   0;  end
                10'b11111_00010:    begin   ready_temp_csrWr    =   5'b11111;   csrWr_num   =   1;  end
                10'b11111_00100:    begin   ready_temp_csrWr    =   5'b11111;   csrWr_num   =   2;  end
                10'b11111_01000:    begin   ready_temp_csrWr    =   5'b11111;   csrWr_num   =   3;  end
                10'b11111_10000:    begin   ready_temp_csrWr    =   5'b11111;   csrWr_num   =   4;  end
                10'b11111_???11:    begin   ready_temp_csrWr    =   5'b00001;   csrWr_num   =   0;  end
                10'b11111_??101:    begin   ready_temp_csrWr    =   5'b00011;   csrWr_num   =   0;  end
                10'b11111_?1001:    begin   ready_temp_csrWr    =   5'b00111;   csrWr_num   =   0;  end
                10'b11111_10001:    begin   ready_temp_csrWr    =   5'b01111;   csrWr_num   =   0;  end
                10'b11111_??110:    begin   ready_temp_csrWr    =   5'b00011;   csrWr_num   =   1;  end
                10'b11111_?1010:    begin   ready_temp_csrWr    =   5'b00111;   csrWr_num   =   1;  end
                10'b11111_10010:    begin   ready_temp_csrWr    =   5'b01111;   csrWr_num   =   1;  end
                10'b11111_?1100:    begin   ready_temp_csrWr    =   5'b00111;   csrWr_num   =   2;  end
                10'b11111_10100:    begin   ready_temp_csrWr    =   5'b01111;   csrWr_num   =   2;  end
                10'b11111_11000:    begin   ready_temp_csrWr    =   5'b01111;   csrWr_num   =   3;  end

                default:            begin   ready_temp_csrWr    =   5'b00000;   csrWr_num   =   7;  end
            endcase

            // excp 顶格退休
            casez (isExcp_vec)
                5'b????1:   begin   ready_temp_excp =   5'b00001;   find_Excp   =   ready_vec[0];   end
                5'b???10:   begin   ready_temp_excp =   5'b00001;   find_Excp   =   0;              end
                5'b??100:   begin   ready_temp_excp =   5'b00011;   find_Excp   =   0;              end
                5'b?1000:   begin   ready_temp_excp =   5'b00111;   find_Excp   =   0;              end
                5'b10000:   begin   ready_temp_excp =   5'b01111;   find_Excp   =   0;              end
                default:    begin   ready_temp_excp =   5'b11111;   find_Excp   =   0;              end
            endcase

            // ertn 顶格退休
            casez (isErtn_vec)
                5'b????1:   begin   ready_temp_ertn =   5'b00001;   find_Ertn   =   ready_vec[0] & ~find_Excp;  end
                5'b???10:   begin   ready_temp_ertn =   5'b00001;   find_Ertn   =   0;                          end
                5'b??100:   begin   ready_temp_ertn =   5'b00011;   find_Ertn   =   0;                          end
                5'b?1000:   begin   ready_temp_ertn =   5'b00111;   find_Ertn   =   0;                          end
                5'b10000:   begin   ready_temp_ertn =   5'b01111;   find_Ertn   =   0;                          end
                default:    begin   ready_temp_ertn =   5'b11111;   find_Ertn   =   0;                          end
            endcase

            // idle 顶格退休
            casez (isIdle_vec)
                5'b????1:   begin   ready_temp_idle =   5'b00001;   find_Idle   =   ready_vec[0] & ~find_Excp;  end
                5'b???10:   begin   ready_temp_idle =   5'b00001;   find_Idle   =   0;                          end
                5'b??100:   begin   ready_temp_idle =   5'b00011;   find_Idle   =   0;                          end
                5'b?1000:   begin   ready_temp_idle =   5'b00111;   find_Idle   =   0;                          end
                5'b10000:   begin   ready_temp_idle =   5'b01111;   find_Idle   =   0;                          end
                default:    begin   ready_temp_idle =   5'b11111;   find_Idle   =   0;                          end
            endcase

            ready_mask  =   ready_temp_store & ready_temp_branch & ready_temp_excp & ready_temp_csrWr & ready_temp_ertn & ready_temp_idle;
            find_Store  =   (store_num == 7 || ready_mask[store_num] == 0 || find_Excp == 1)? 0 : 1;
            find_Branch =   (Branch_num == 7 || ready_mask[Branch_num] == 0 || find_Excp == 1)? 0 : 1;
            find_csrWr  =   (csrWr_num == 7 || ready_mask[csrWr_num] == 0 || find_Excp == 1)? 0 : 1;
        end
        else begin
            ready_mask  =   (ready_vec[0] == 1)? 5'b00001: 5'b00000;
            find_Excp   =   (isExcp_vec[0] == 1 && ready_vec[0] == 1)? 1 : 0;
            find_Branch =   (isBranch_vec[0] == 1 && ready_vec[0] == 1 && find_Excp == 0)? 1 : 0;
            find_Store  =   (isStore_vec[0] == 1 && ready_vec[0] == 1 && find_Excp == 0)? 1 : 0;
            find_csrWr  =   (csrWr_vec[0] == 1 && ready_vec[0] == 1 && find_Excp == 0)? 1 : 0;
            find_Ertn   =   (isErtn_vec[0] == 1 && ready_vec[0] == 1 && find_Excp == 0)? 1 : 0;
            Branch_num  =   find_Branch? 0 : 7;
            find_Idle   =   (isIdle_vec[0] == 1 && ready_vec[0] == 1 && find_Excp == 0)? 1 : 0;
        end
    end

endmodule