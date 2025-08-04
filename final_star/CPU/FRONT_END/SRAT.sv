module SRAT (
    input               clk,
    input               rst,
    input               flush_srat,
    input               stall_srat,
    output              full_prf,

    input   [ 4 : 0]    Rj              [2 : 0],
    input   [ 4 : 0]    Rk              [2 : 0],
    input   [ 4 : 0]    Rd              [2 : 0],
    input               RegWr           [2 : 0],
    output  [ 5 : 0]    Pj              [2 : 0],
    output              valid_Pj        [2 : 0],
    output  [ 5 : 0]    Pk              [2 : 0],
    output              valid_Pk        [2 : 0],
    output  [ 5 : 0]    Pd              [2 : 0],
    output  [ 5 : 0]    Pd_old          [2 : 0],
    output              valid_Pd_old    [2 : 0],

    // from CDB (broadcast)
    input               ready_cdb       [4 : 0],
    input               RegWr_cdb       [4 : 0],
    input   [ 5 : 0]    Pd_cdb          [4 : 0],
    // from ROB
    input               ready_rob       [4 : 0],
    input               RegWr_rob       [4 : 0],
    input   [ 5 : 0]    Pd_old_rob      [4 : 0],
    // from aRAT
    input   [ 5 : 0]    P_list_arat     [31: 0],
    input   [63 : 0]    free_list_arat
);

    reg     [ 5 : 0]    P_list          [31: 0];
    reg     [63 : 0]    valid_list;
    reg     [63 : 0]    free_list;

    // read Px-valid_Px
    assign  Pj[0]           =   P_list[Rj[0]];
    assign  Pk[0]           =   P_list[Rk[0]];
    assign  Pd_old[0]       =   P_list[Rd[0]];
    assign  valid_Pj[0]     =   valid_list[Pj[0]];
    assign  valid_Pk[0]     =   valid_list[Pk[0]];
    assign  valid_Pd_old[0] =   valid_list[Pd_old[0]];

    assign  Pj[1]           =   (Rj[1] != 0 && Rj[1] == Rd[0] && RegWr[0])? Pd[0] : P_list[Rj[1]];
    assign  Pk[1]           =   (Rk[1] != 0 && Rk[1] == Rd[0] && RegWr[0])? Pd[0] : P_list[Rk[1]];
    assign  Pd_old[1]       =   (Rd[1] == Rd[0]               && RegWr[0])? Pd[0] : P_list[Rd[1]];
    assign  valid_Pj[1]     =   (Rj[1] != 0 && Rj[1] == Rd[0] && RegWr[0])? 0 : valid_list[Pj[1]];
    assign  valid_Pk[1]     =   (Rk[1] != 0 && Rk[1] == Rd[0] && RegWr[0])? 0 : valid_list[Pk[1]];
    assign  valid_Pd_old[1] =   (Rd[1] != 0 && Rd[1] == Rd[0] && RegWr[0])? 0 : valid_list[Pd_old[1]];

    assign  Pj[2]           =   (Rj[2] != 0 && Rj[2] == Rd[1] && RegWr[1])? Pd[1] :
                                (Rj[2] != 0 && Rj[2] == Rd[0] && RegWr[0])? Pd[0] : P_list[Rj[2]];
    assign  Pk[2]           =   (Rk[2] != 0 && Rk[2] == Rd[1] && RegWr[1])? Pd[1] :
                                (Rk[2] != 0 && Rk[2] == Rd[0] && RegWr[0])? Pd[0] : P_list[Rk[2]];
    assign  Pd_old[2]       =   (Rd[2] == Rd[1]               && RegWr[1])? Pd[1] :
                                (Rd[2] == Rd[0]               && RegWr[0])? Pd[0] : P_list[Rd[2]];
    assign  valid_Pj[2]     =   (Rj[2] != 0 && Rj[2] == Rd[1] && RegWr[1])? 0 :
                                (Rj[2] != 0 && Rj[2] == Rd[0] && RegWr[0])? 0 : valid_list[Pj[2]];
    assign  valid_Pk[2]     =   (Rk[2] != 0 && Rk[2] == Rd[1] && RegWr[1])? 0 :
                                (Rk[2] != 0 && Rk[2] == Rd[0] && RegWr[0])? 0 : valid_list[Pk[2]];
    assign  valid_Pd_old[2] =   (Rd[2] != 0 && Rd[2] == Rd[1] && RegWr[1])? 0 :
                                (Rd[2] != 0 && Rd[2] == Rd[0] && RegWr[0])? 0 : valid_list[Pd_old[2]];


    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (integer i = 0; i < 32; i = i + 1) begin
                P_list[i]   <=  i;
            end
            valid_list      <=  64'h0000_0000_ffff_ffff;
            free_list       <=  64'hffff_ffff_0000_0000;
        end
        else begin
            if (flush_srat) begin
                P_list      <=  P_list_arat;
                valid_list  <=  ~free_list_arat;
                free_list   <=  free_list_arat;
            end
            else begin
                
                // write new Pd
                if (!stall_srat) begin
                    if (RegWr[0] == 1) begin
                        free_list[Pd[0]]        <=  0;
                        if (Rd[0] != 0 && !((RegWr[1] == 1 && Rd[0] == Rd[1]) || (RegWr[2] == 1 && Rd[0] == Rd[2]))) begin
                            P_list[Rd[0]]       <=  Pd[0];
                            valid_list[Pd[0]]   <=  0;
                        end
                    end
                    if (RegWr[1] == 1) begin
                        free_list[Pd[1]]        <=  0;
                        if (Rd[1] != 0 && !(RegWr[2] == 1 && Rd[1] == Rd[2])) begin
                            P_list[Rd[1]]       <=  Pd[1];
                            valid_list[Pd[1]]   <=  0;
                        end
                    end
                    if (RegWr[2] == 1) begin
                        free_list[Pd[2]]        <=  0;
                        if (Rd[2] != 0) begin
                            P_list[Rd[2]]       <=  Pd[2];
                            valid_list[Pd[2]]   <=  0;
                        end
                    end
                end

                // CDB release valid_list
                for (integer i = 0; i < 5; i = i + 1) begin
                    if (ready_cdb[i] & RegWr_cdb[i]) begin
                        valid_list[Pd_cdb[i]]   <=  1;
                    end
                end

                // ROB release free_list
                for (integer i = 0; i < 5; i = i + 1) begin
                    if (ready_rob[i] && RegWr_rob[i] && Pd_old_rob[i] != 0) begin
                        free_list[Pd_old_rob[i]]<=  1;
                    end
                end
            end
        end
    end

    FREELIST u_FREELIST (
        .free_list          (free_list),
        .Rd                 (Rd),
        .Pd                 (Pd),
        .full_prf           (full_prf)
    );

endmodule