module PRF (
    input               clk,
    input               rst,

    input   [ 5 : 0]    Pj_alu,
    input   [ 5 : 0]    Pk_alu,
    output  [31 : 0]    dataj_alu,
    output  [31 : 0]    datak_alu,

    input   [ 5 : 0]    Pj_mdu,
    input   [ 5 : 0]    Pk_mdu,
    output  [31 : 0]    dataj_mdu,
    output  [31 : 0]    datak_mdu,

    input   [ 5 : 0]    Pj_agu,
    output  [31 : 0]    dataj_agu,

    input   [ 5 : 0]    Px_lsu,
    output  [31 : 0]    datax_lsu,

    input   [ 5 : 0]    Pj_bru,
    input   [ 5 : 0]    Pd_old_bru,
    output  [31 : 0]    dataj_bru,
    output  [31 : 0]    datad_old_bru,

    input   [ 5 : 0]    Pj_csr,
    input   [ 5 : 0]    Pd_old_csr,
    output  [31 : 0]    dataj_csr,
    output  [31 : 0]    datad_old_csr,

    // from CDB
    input               ready_cdb   [4 : 0],
    input               RegWr_cdb   [4 : 0],
    input   [ 5 : 0]    Pd_cdb      [4 : 0],
    input   [31 : 0]    Result_cdb  [4 : 0]
);

    reg     [31 : 0]    prf         [63: 0];

    assign  dataj_alu       =   prf[Pj_alu];
    assign  datak_alu       =   prf[Pk_alu];

    assign  dataj_mdu       =   prf[Pj_mdu];
    assign  datak_mdu       =   prf[Pk_mdu];

    assign  dataj_agu       =   prf[Pj_agu];

    assign  datax_lsu       =   prf[Px_lsu];

    assign  dataj_bru       =   prf[Pj_bru];
    assign  datad_old_bru   =   prf[Pd_old_bru];

    assign  dataj_csr       =   prf[Pj_csr];
    assign  datad_old_csr   =   prf[Pd_old_csr];

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (integer i = 0; i < 64; i = i + 1) begin
                prf[i]              <=  '0;
            end
        end
        else begin
            for (integer i = 0; i < 5; i = i + 1) begin
                if (ready_cdb[i] && RegWr_cdb[i] && Pd_cdb[i] != 0) begin
                    prf[Pd_cdb[i]]  <=  Result_cdb[i];
                end
            end
        end
    end

endmodule