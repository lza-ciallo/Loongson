`include "../defs.svh"

module MDUQ (
    input                   clk,
    input                   rst,
    input                   flush_mduq,
    input                   stall_in,
    output                  full_mduq,

    input                   ready_pc    [2 : 0],
    input       [ 5 : 0]    Pj          [2 : 0],
    input                   valid_Pj    [2 : 0],
    input       [ 5 : 0]    Pk          [2 : 0],
    input                   valid_Pk    [2 : 0],
    input       [ 5 : 0]    Pd          [2 : 0],
    input       [ 2 : 0]    Type        [2 : 0],
    input       [ 3 : 0]    Conf        [2 : 0],
    input                   RegWr       [2 : 0],

    output  reg             ready_awake,
    output  reg [ 5 : 0]    Pj_awake,
    output  reg [ 5 : 0]    Pk_awake,
    output  reg [ 5 : 0]    Pd_awake,
    output  reg [ 3 : 0]    Conf_awake,
    output  reg             RegWr_awake,
    output  reg [ 5 : 0]    tag_rob_awake,

    // from ROB
    input       [ 5 : 0]    ptr_old,
    input       [ 5 : 0]    tag_rob     [2 : 0],

    // from CDB
    input                   ready_cdb   [4 : 0],
    input                   RegWr_cdb   [4 : 0],
    input       [ 5 : 0]    Pd_cdb      [4 : 0]
);

    typedef struct packed {
        reg     [ 5 : 0]    Pj;
        reg     [ 5 : 0]    Pk;
        reg     [ 5 : 0]    Pd;
        reg     [ 3 : 0]    Conf;
        reg                 RegWr;
        reg     [ 5 : 0]    tag_rob;
    } mduq_entry;

    mduq_entry  mduq_list       [15 : 0];

    reg     [15 : 0]    ready_list;
    reg     [15 : 0]    ready_Pj_list;
    reg     [15 : 0]    ready_Pk_list;

    integer     empty_entry     [ 2 : 0];
    integer     awake_entry;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            ready_list                                      <=  '0;
            ready_Pj_list                                   <=  '0;
            ready_Pk_list                                   <=  '0;
            for (integer i = 0; i < 16; i = i + 1) begin
                mduq_list[i]                                <=  '0;
            end
            ready_awake                                     <=  '0;
            {Pj_awake, Pk_awake, Pd_awake, Conf_awake,
                RegWr_awake, tag_rob_awake}                 <=  '0;
        end
        else begin
            if (flush_mduq) begin
                ready_list                                  <=  '0;
                ready_Pj_list                               <=  '0;
                ready_Pk_list                               <=  '0;
                for (integer i = 0; i < 16; i = i + 1) begin
                    mduq_list[i]                            <=  '0;
                end
                ready_awake                                 <=  '0;
                {Pj_awake, Pk_awake, Pd_awake, Conf_awake,
                    RegWr_awake, tag_rob_awake}             <=  '0;
            end
            else begin
                
                // write in 3 uop's
                if (!full_mduq && !stall_in) begin
                    for (integer i = 0; i < 3; i = i + 1) begin
                        if (Type[i] == `MDU_TYPE && ready_pc[i]) begin
                            ready_list[empty_entry[i]]      <=  1;
                            ready_Pj_list[empty_entry[i]]   <=  (Pj[i] == Pd_cdb[0] && ready_cdb[0] && RegWr_cdb[0]) ||
                                                                (Pj[i] == Pd_cdb[1] && ready_cdb[1] && RegWr_cdb[1]) ||
                                                                (Pj[i] == Pd_cdb[2] && ready_cdb[2] && RegWr_cdb[2]) ||
                                                                (Pj[i] == Pd_cdb[3] && ready_cdb[3] && RegWr_cdb[3]) ||
                                                                (Pj[i] == Pd_cdb[4] && ready_cdb[4] && RegWr_cdb[4])? 1 : valid_Pj[i];
                            ready_Pk_list[empty_entry[i]]   <=  (Pk[i] == Pd_cdb[0] && ready_cdb[0] && RegWr_cdb[0]) ||
                                                                (Pk[i] == Pd_cdb[1] && ready_cdb[1] && RegWr_cdb[1]) ||
                                                                (Pk[i] == Pd_cdb[2] && ready_cdb[2] && RegWr_cdb[2]) ||
                                                                (Pk[i] == Pd_cdb[3] && ready_cdb[3] && RegWr_cdb[3]) ||
                                                                (Pk[i] == Pd_cdb[4] && ready_cdb[4] && RegWr_cdb[4])? 1 : valid_Pk[i];
                            mduq_list[empty_entry[i]]       <=  {Pj[i], Pk[i], Pd[i], Conf[i], RegWr[i], tag_rob[i]};
                        end
                    end
                end

                // awake 1 uop
                if (awake_entry != 16) begin
                    ready_awake                                     <=  ready_list[awake_entry];
                    {Pj_awake, Pk_awake, Pd_awake, Conf_awake,
                        RegWr_awake, tag_rob_awake}                 <=  mduq_list[awake_entry];
                    ready_list[awake_entry]                         <=  '0;
                    ready_Pj_list[awake_entry]                      <=  '0;
                    ready_Pk_list[awake_entry]                      <=  '0;
                    mduq_list[awake_entry]                          <=  '0;
                end
                else begin
                    ready_awake                                     <=  '0;
                    {Pj_awake, Pk_awake, Pd_awake, Conf_awake,
                        RegWr_awake, tag_rob_awake}                 <=  '0;
                end

                // CDB
                for (integer i = 0; i < 5; i = i + 1) begin
                    if (ready_cdb[i] && RegWr_cdb[i]) begin
                        for (integer j = 0; j < 16; j = j + 1) begin
                            if (mduq_list[j].Pj == Pd_cdb[i] && ready_list[j] == 1) begin
                                ready_Pj_list[j]    <=  1;
                            end
                            if (mduq_list[j].Pk == Pd_cdb[i] && ready_list[j] == 1) begin
                                ready_Pk_list[j]    <=  1;
                            end
                        end
                    end
                end
            end
        end
    end

    // generate 1 oldest-first awake_entry
    reg     [ 6 : 0]    tag_rob_shifted [15 : 0];
    integer             compare_1       [ 7 : 0];
    integer             compare_2       [ 3 : 0];
    integer             compare_3       [ 1 : 0];
    integer             compare_4;
    always @(*) begin
        for (integer i = 0; i < 16; i = i + 1) begin
            tag_rob_shifted[i]  =   (ready_list[i] & ready_Pj_list[i] & ready_Pk_list[i])? (mduq_list[i].tag_rob - ptr_old) & 7'b011_1111 : 7'b100_0000;
        end
        for (integer i = 0; i < 8; i = i + 1) begin
            compare_1[i]        =   (tag_rob_shifted[2*i] < tag_rob_shifted[2*i+1])? 2*i : 2*i+1;
        end
        for (integer i = 0; i < 4; i = i + 1) begin
            compare_2[i]        =   (tag_rob_shifted[compare_1[2*i]] < tag_rob_shifted[compare_1[2*i+1]])? compare_1[2*i] : compare_1[2*i+1];
        end
        for (integer i = 0; i < 2; i = i + 1) begin
            compare_3[i]        =   (tag_rob_shifted[compare_2[2*i]] < tag_rob_shifted[compare_2[2*i+1]])? compare_2[2*i] : compare_2[2*i+1];
        end
        compare_4               =   (tag_rob_shifted[compare_3[0]] < tag_rob_shifted[compare_3[1]])? compare_3[0] : compare_3[1];
        awake_entry             =   (tag_rob_shifted[compare_4] == 7'b100_0000)? 16 : compare_4;
    end

    // generate 3 empty_entry's
    wire    [15 : 0]    ready_list_wire [ 2 : 0];
    assign  ready_list_wire[0]  =   ready_list;
    assign  ready_list_wire[1]  =   ready_list_wire[0] | (16'd1 << empty_entry[0]);
    assign  ready_list_wire[2]  =   ready_list_wire[1] | (16'd1 << empty_entry[1]);
    assign  full_mduq           =   (empty_entry[0] == 16 || empty_entry[1] == 16 || empty_entry[2] == 16)? 1 : 0;

    generate
        for (genvar i = 0; i < 3; i = i + 1) begin
            always @(*) begin
                casez (ready_list_wire[i])
                    16'b????_????_????_???0:    empty_entry[i]  =   0;
                    16'b????_????_????_??01:    empty_entry[i]  =   1;
                    16'b????_????_????_?011:    empty_entry[i]  =   2;
                    16'b????_????_????_0111:    empty_entry[i]  =   3;

                    16'b????_????_???0_1111:    empty_entry[i]  =   4;
                    16'b????_????_??01_1111:    empty_entry[i]  =   5;
                    16'b????_????_?011_1111:    empty_entry[i]  =   6;
                    16'b????_????_0111_1111:    empty_entry[i]  =   7;

                    16'b????_???0_1111_1111:    empty_entry[i]  =   8;
                    16'b????_??01_1111_1111:    empty_entry[i]  =   9;
                    16'b????_?011_1111_1111:    empty_entry[i]  =   10;
                    16'b????_0111_1111_1111:    empty_entry[i]  =   11;

                    16'b???0_1111_1111_1111:    empty_entry[i]  =   12;
                    16'b??01_1111_1111_1111:    empty_entry[i]  =   13;
                    16'b?011_1111_1111_1111:    empty_entry[i]  =   14;
                    16'b0111_1111_1111_1111:    empty_entry[i]  =   15;

                    default:                    empty_entry[i]  =   16;
                endcase
            end
        end
    endgenerate

endmodule