`include "../defs.svh"

module BACK_END (
    input               clk,
    input               rst,
    input               flush_back,
    input               flush_lsu_out,
    input               stall_lsuq,
    input               stall_mem_request,
    output              full_dfifo,

    input               ready_alu,
    input   [ 5 : 0]    Pj_alu,
    input   [ 5 : 0]    Pk_alu,
    input   [ 5 : 0]    Pd_alu,
    input   [31 : 0]    imm_alu,
    input   [ 3 : 0]    Conf_alu,
    input               isImm_alu,
    input               RegWr_alu,
    input   [ 5 : 0]    tag_rob_alu,

    input               ready_mdu,
    input   [ 5 : 0]    Pj_mdu,
    input   [ 5 : 0]    Pk_mdu,
    input   [ 5 : 0]    Pd_mdu,
    input   [ 3 : 0]    Conf_mdu,
    input               RegWr_mdu,
    input   [ 5 : 0]    tag_rob_mdu,

    input               ready_agu,
    input   [ 5 : 0]    Pj_agu,
    input   [31 : 0]    imm_agu,
    input   [ 5 : 0]    tag_rob_agu,

    input               ready_lsu,
    input   [ 5 : 0]    Px_lsu,
    input   [31 : 0]    Addr_lsu,
    input   [ 3 : 0]    Conf_lsu,
    input               RegWr_lsu,
    input   [ 5 : 0]    tag_rob_lsu,
    input               has_excp_lsu,

    input               ready_bru,
    input   [ 5 : 0]    Pj_bru,
    input   [ 5 : 0]    Pd_old_bru,
    input   [ 3 : 0]    Conf_bru,
    input   [ 5 : 0]    tag_rob_bru,
    input   [31 : 0]    target_predict_bru,
    input   [31 : 0]    imm_bru,

    input               ready_dir,
    input   [31 : 0]    imm_dir,
    input   [ 5 : 0]    Pd_dir,
    input               RegWr_dir,
    input   [ 3 : 0]    Conf_dir,
    input   [ 5 : 0]    tag_rob_dir,

    input   [ 5 : 0]    tag_rob_csr,
    input   [ 3 : 0]    Conf_csr,
    input   [ 5 : 0]    Pj_csr,
    input   [ 5 : 0]    Pd_old_csr,
    input   [ 5 : 0]    Pd_csr,
    input   [13 : 0]    csr_addr_csr,
    input               ready_csr,
    input               RegWr_csr,
    input               csrWr_csr,

    // CDB
    output              ready_cdb       [4 : 0],
    output              RegWr_cdb       [4 : 0],
    output  [ 5 : 0]    Pd_cdb          [4 : 0],
    // back_end to ROB
    output  [ 5 : 0]    tag_rob_Result  [5 : 0],
    // BRU to ROB
    output              ready_Branch,
    output              Branch,
    output              isJIRL,
    output  [31 : 0]    target_real,
    // LSU to ROB
    output              has_excp_lsu_out,
    output              excp_level_lsu_out,
    
    // AGU to LSUQ
    output              ready_Addr,
    output  [ 5 : 0]    tag_rob_Addr,
    output  [31 : 0]    Addr,
    // from ROB
    input               isStore_rob,

    // to/from DMEM
    output              MemWr_dmem,
    output              MemRd_dmem,
    output  [31 : 0]    data_in_dmem,
    output  [31 : 0]    Addr_dmem,
    output  [ 3 : 0]    Conf_dmem,
    input   [31 : 0]    data_out_dmem,

    // CSR
    input   [63 : 0]    timer_64,
    input   [31 : 0]    tid,

    output  [13 : 0]    csrRd_addr,
    input   [31 : 0]    data_csrRd,
    output              csrWr,
    output  [13 : 0]    csrWr_addr,
    output  [31 : 0]    data_csrWr,

    output  [31 : 0]    Result_dmem
);

    assign  Result_dmem =   Result_cdb[2];

    assign  csrRd_addr  =   csr_addr_csr;

    // CDB: ALU, MDU, LSU, DIR, CSR
    // tag_rob_Result: ALU, MDU, LSU, DIR, CSR, BRU
    wire    [31 : 0]    Result_cdb  [4 : 0];

    // [3]: DIR
    assign  {ready_cdb[3], RegWr_cdb[3], Pd_cdb[3], tag_rob_Result[3]}   =   {ready_dir, RegWr_dir, Pd_dir, tag_rob_dir};
    assign  Result_cdb[3]   =   imm_dir;
    
    // [4]: CSR
    // 最下面

    // READ
    wire    [31 : 0]    dataj_alu;
    wire    [31 : 0]    datak_alu;
    wire    [31 : 0]    busB_alu_temp;
    assign  busB_alu_temp = isImm_alu? imm_alu : datak_alu;

    wire    [31 : 0]    dataj_mdu;
    wire    [31 : 0]    datak_mdu;

    wire    [31 : 0]    dataj_agu;

    wire    [31 : 0]    datax_lsu;

    wire    [31 : 0]    dataj_bru;
    wire    [31 : 0]    datad_old_bru;

    wire    [31 : 0]    dataj_csr;
    wire    [31 : 0]    datad_old_csr;
    wire    [31 : 0]    data_csrWr_temp;
    assign  data_csrWr_temp =   (Conf_csr == `CSRXG_CONF)? (datad_old_csr & dataj_csr) | (data_csrRd & ~dataj_csr) :
                                (Conf_csr == `CSRWR_CONF)? datad_old_csr : '0;

    wire    [31 : 0]    dick;

    CPUCONF u_CPUCONF (
        .cpuconf_id     (dataj_csr),
        .cpuconf_value  (dick)
    ); 

    wire    [31 : 0]    data_WrReg_0;
    assign  data_WrReg_0    =   (Conf_csr == `CNTID_CONF)? tid              :
                                (Conf_csr == `CNTVL_CONF)? timer_64[31: 0]  :
                                (Conf_csr == `CNTVL_CONF)? timer_64[63:32]  :
                                (Conf_csr == `CPU_CONF)?   dick             : data_csrRd;

    PRF u_PRF (
        .clk            (clk),
        .rst            (rst),

        .Pj_alu         (Pj_alu),
        .Pk_alu         (Pk_alu),
        .dataj_alu      (dataj_alu),
        .datak_alu      (datak_alu),

        .Pj_mdu         (Pj_mdu),
        .Pk_mdu         (Pk_mdu),
        .dataj_mdu      (dataj_mdu),
        .datak_mdu      (datak_mdu),

        .Pj_agu         (Pj_agu),
        .dataj_agu      (dataj_agu),

        .Px_lsu         (Px_lsu),
        .datax_lsu      (datax_lsu),

        .Pj_bru         (Pj_bru),
        .Pd_old_bru     (Pd_old_bru),
        .dataj_bru      (dataj_bru),
        .datad_old_bru  (datad_old_bru),

        .Pj_csr         (Pj_csr),
        .Pd_old_csr     (Pd_old_csr),
        .dataj_csr      (dataj_csr),
        .datad_old_csr  (datad_old_csr),

        // from CDB
        .ready_cdb      (ready_cdb),
        .RegWr_cdb      (RegWr_cdb),
        .Pd_cdb         (Pd_cdb),
        .Result_cdb     (Result_cdb)
    );

    // EX\LSU
    wire    [31 : 0]    busA_alu;
    wire    [31 : 0]    busB_alu;
    wire    [ 3 : 0]    Conf_alu_r;
    wire    [ 5 : 0]    Pd_alu_r;
    wire                ready_alu_r;
    wire                RegWr_alu_r;
    wire    [ 5 : 0]    tag_rob_alu_r;

    wire    [31 : 0]    busA_mdu;
    wire    [31 : 0]    busB_mdu;
    wire    [ 3 : 0]    Conf_mdu_r;
    wire    [ 5 : 0]    Pd_mdu_r;
    wire                ready_mdu_r;
    wire                RegWr_mdu_r;
    wire    [ 5 : 0]    tag_rob_mdu_r;

    wire    [31 : 0]    dataj_agu_r;
    wire    [31 : 0]    imm_agu_r;
    wire                ready_agu_r;
    wire    [ 5 : 0]    tag_rob_agu_r;

    wire    [31 : 0]    dataj_bru_r;
    wire    [31 : 0]    datad_old_bru_r;
    wire    [ 3 : 0]    Conf_bru_r;
    wire                ready_bru_r;
    wire    [ 5 : 0]    tag_rob_bru_r;
    wire    [31 : 0]    target_predict_bru_r;
    wire    [31 : 0]    imm_bru_r;

    // READ-EX\LSU
    localparam  BW_READ =   (32*2+4+6+1*2+6) + (32*2+4+6+1*2+6) + (32*2+1+6) + (32*2+4+1+6+32*2);    // ALU, MDU, AGU, BRU
    wire    [BW_READ - 1 : 0]   bunch_READ;
    wire    [BW_READ - 1 : 0]   bunch_READ_r;
    assign  bunch_READ  =   {dataj_alu, busB_alu_temp, Conf_alu, Pd_alu, ready_alu, RegWr_alu, tag_rob_alu,
                            dataj_mdu, datak_mdu, Conf_mdu, Pd_mdu, ready_mdu, RegWr_mdu, tag_rob_mdu,
                            dataj_agu, imm_agu, ready_agu, tag_rob_agu,
                            dataj_bru, datad_old_bru, Conf_bru, ready_bru, tag_rob_bru, target_predict_bru, imm_bru};
    assign  {busA_alu, busB_alu, Conf_alu_r, Pd_alu_r, ready_alu_r, RegWr_alu_r, tag_rob_alu_r,
            busA_mdu, busB_mdu, Conf_mdu_r, Pd_mdu_r, ready_mdu_r, RegWr_mdu_r, tag_rob_mdu_r,
            dataj_agu_r, imm_agu_r, ready_agu_r, tag_rob_agu_r,
            dataj_bru_r, datad_old_bru_r, Conf_bru_r, ready_bru_r, tag_rob_bru_r, target_predict_bru_r, imm_bru_r}  =   bunch_READ_r;

    REGISTER #(
        .BW             (BW_READ)
    ) u_REG_READ_ELSE (
        .clk            (clk),
        .rst            (rst),
        .flush          (flush_back),
        .stall          (1'b0),

        .data_in        (bunch_READ),
        .data_out       (bunch_READ_r)
    );

    ALU u_ALU (
        .clk            (clk),
        .rst            (rst),
        .flush_back     (flush_back),

        .busA           (busA_alu),
        .busB           (busB_alu),
        .Conf           (Conf_alu_r),
        .Result_r       (Result_cdb[0]),

        .Pd             (Pd_alu_r),
        .ready          (ready_alu_r),
        .RegWr          (RegWr_alu_r),
        .tag_rob        (tag_rob_alu_r),

        .Pd_r           (Pd_cdb[0]),
        .ready_r        (ready_cdb[0]),
        .RegWr_r        (RegWr_cdb[0]),
        .tag_rob_r      (tag_rob_Result[0])
    );

    MDU u_MDU (
        .clk            (clk),
        .rst            (rst),
        .flush_back     (flush_back),

        .busA           (busA_mdu),
        .busB           (busB_mdu),
        .Conf           (Conf_mdu_r),
        .Result_r       (Result_cdb[1]),

        .Pd             (Pd_mdu_r),
        .ready          (ready_mdu_r),
        .RegWr          (RegWr_mdu_r),
        .tag_rob        (tag_rob_mdu_r),

        .Pd_r           (Pd_cdb[1]),
        .ready_r        (ready_cdb[1]),
        .RegWr_r        (RegWr_cdb[1]),
        .tag_rob_r      (tag_rob_Result[1])
    );

    AGU u_AGU (
        .clk            (clk),
        .rst            (rst),
        .flush_back     (flush_back),

        .dataj          (dataj_agu_r),
        .imm            (imm_agu_r),
        .Addr_r         (Addr),

        .ready          (ready_agu_r),
        .tag_rob        (tag_rob_agu_r),

        .ready_r        (ready_Addr),
        .tag_rob_r      (tag_rob_Addr)
    );

    BRU u_BRU (
        .clk            (clk),
        .rst            (rst),
        .flush_back     (flush_back),

        .dataj          (dataj_bru_r),
        .datad_old      (datad_old_bru_r),
        .Conf           (Conf_bru_r),
        .imm            (imm_bru_r),
        .target_predict (target_predict_bru_r),
        .Branch_r       (Branch),
        .isJIRL_r       (isJIRL),
        .target_real_r  (target_real),

        .ready          (ready_bru_r),
        .tag_rob        (tag_rob_bru_r),
        .ready_r        (ready_Branch),
        .tag_rob_r      (tag_rob_Result[5])
    );

    // LSU
    wire    [31 : 0]    datax_lsu_r;
    wire    [31 : 0]    Addr_lsu_r;
    wire    [ 3 : 0]    Conf_lsu_r;
    wire    [ 5 : 0]    Px_lsu_r;
    wire                ready_lsu_r;
    wire                RegWr_lsu_r;
    wire    [ 5 : 0]    tag_rob_lsu_r;
    wire                has_excp_lsu_r;

    // read-LSU
    localparam  BW_LSU  =   32*2+4+6+1*2+6+1;
    wire    [BW_LSU - 1 : 0]    bunch_LSU;
    wire    [BW_LSU - 1 : 0]    bunch_LSU_r;
    assign  bunch_LSU   =   {datax_lsu, Addr_lsu, Conf_lsu, Px_lsu, ready_lsu, RegWr_lsu, tag_rob_lsu, has_excp_lsu};
    assign  {datax_lsu_r, Addr_lsu_r, Conf_lsu_r, Px_lsu_r, ready_lsu_r, RegWr_lsu_r, tag_rob_lsu_r, has_excp_lsu_r}    =   bunch_LSU_r;

    REGISTER #(
        .BW             (BW_LSU)
    ) u_REG_READ_LSU (
        .clk            (clk),
        .rst            (rst),
        .flush          (flush_back),
        .stall          (stall_lsuq),

        .data_in        (bunch_LSU),
        .data_out       (bunch_LSU_r)
    );

    LSU u_LSU (
        .clk            (clk),
        .rst            (rst),
        .flush_back     (flush_back),
        .flush_lsu_out  (flush_lsu_out),
        .stall_mem_request  (stall_mem_request),
        .stall_lsuq     (stall_lsuq),
        .full_dfifo     (full_dfifo),

        .datax          (datax_lsu_r),
        .Addr           (Addr_lsu_r),
        .Conf           (Conf_lsu_r),
        .Result_r       (Result_cdb[2]),

        .Pd             (Px_lsu_r),
        .ready          (ready_lsu_r),
        .RegWr          (RegWr_lsu_r),
        .tag_rob        (tag_rob_lsu_r),
        .has_excp       (has_excp_lsu_r),

        .Pd_r           (Pd_cdb[2]),
        .ready_r        (ready_cdb[2]),
        .RegWr_r        (RegWr_cdb[2]),
        .tag_rob_r      (tag_rob_Result[2]),

        // from ROB
        .isStore_rob    (isStore_rob),
        // to/from DMEM
        .MemWr_dmem     (MemWr_dmem),
        .MemRd_dmem     (MemRd_dmem),
        .data_in_dmem   (data_in_dmem),
        .Addr_dmem      (Addr_dmem),
        .Conf_dmem      (Conf_dmem),
        .data_out_dmem  (data_out_dmem),
        .has_excp_r     (has_excp_lsu_out),
        .excp_level     (excp_level_lsu_out)
    );

    // read-CSR
    localparam  BW_CSR  =   32*2+14+6+1*3+6;
    wire    [BW_CSR - 1 : 0]    bunch_CSR;
    wire    [BW_CSR - 1 : 0]    bunch_CSR_r;
    assign  bunch_CSR   =   {data_csrWr_temp, data_WrReg_0, csr_addr_csr, Pd_csr, RegWr_csr, csrWr_csr, ready_csr, tag_rob_csr};
    assign  {data_csrWr, Result_cdb[4], csrWr_addr, Pd_cdb[4], RegWr_cdb[4], csrWr, ready_cdb[4], tag_rob_Result[4]} =   bunch_CSR_r;

    REGISTER #(
        .BW             (BW_CSR)
    ) u_REG_READ_CSR (
        .clk            (clk),
        .rst            (rst),
        .flush          (flush_back),
        .stall          (1'b0),

        .data_in        (bunch_CSR),
        .data_out       (bunch_CSR_r)
    );

endmodule