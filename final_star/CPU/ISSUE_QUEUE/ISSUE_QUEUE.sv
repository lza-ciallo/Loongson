module ISSUE_QUEUE (
    input               clk,
    input               rst,
    input               flush_queue,
    input               stall_in,
    input               stall_lsuq,
    output              full_queue,

    input               ready_pc        [2 : 0],
    input   [ 5 : 0]    Pj              [2 : 0],
    input               valid_Pj        [2 : 0],
    input   [ 5 : 0]    Pk              [2 : 0],
    input               valid_Pk        [2 : 0],
    input   [ 5 : 0]    Pd              [2 : 0],
    input   [ 5 : 0]    Pd_old          [2 : 0],
    input               valid_Pd_old    [2 : 0],
    input   [31 : 0]    imm             [2 : 0],
    input   [ 2 : 0]    Type            [2 : 0],
    input   [ 3 : 0]    Conf            [2 : 0],
    input               isImm           [2 : 0],
    input               RegWr           [2 : 0],
    input   [31 : 0]    pc              [2 : 0],
    input   [31 : 0]    target_predict  [2 : 0],
    input               has_excp        [2 : 0],
    input   [13 : 0]    csr_addr        [2 : 0],
    input               csrWr           [2 : 0],

    output              ready_alu,
    output  [ 5 : 0]    Pj_alu,
    output  [ 5 : 0]    Pk_alu,
    output  [ 5 : 0]    Pd_alu,
    output  [31 : 0]    imm_alu,
    output  [ 3 : 0]    Conf_alu,
    output              isImm_alu,
    output              RegWr_alu,
    output  [ 5 : 0]    tag_rob_alu,

    output              ready_mdu,
    output  [ 5 : 0]    Pj_mdu,
    output  [ 5 : 0]    Pk_mdu,
    output  [ 5 : 0]    Pd_mdu,
    output  [ 3 : 0]    Conf_mdu,
    output              RegWr_mdu,
    output  [ 5 : 0]    tag_rob_mdu,

    output              ready_agu,
    output  [ 5 : 0]    Pj_agu,
    output  [31 : 0]    imm_agu,
    output  [ 5 : 0]    tag_rob_agu,

    output              ready_lsu,
    output  [ 5 : 0]    Px_lsu,
    output  [31 : 0]    Addr_lsu,
    output  [ 3 : 0]    Conf_lsu,
    output              RegWr_lsu,
    output  [ 5 : 0]    tag_rob_lsu,
    output              has_excp_lsu,

    output              ready_bru,
    output  [ 5 : 0]    Pj_bru,
    output  [ 5 : 0]    Pd_old_bru,
    output  [ 3 : 0]    Conf_bru,
    output  [ 5 : 0]    tag_rob_bru,
    output  [31 : 0]    target_predict_bru,
    output  [31 : 0]    imm_bru,

    output              ready_dir,
    output  [31 : 0]    imm_dir,
    output  [ 5 : 0]    Pd_dir,
    output              RegWr_dir,
    output  [ 3 : 0]    Conf_dir,
    output  [ 5 : 0]    tag_rob_dir,
    output              isJIRL_dir,

    output  [ 5 : 0]    tag_rob_csr,
    output  [ 3 : 0]    Conf_csr,
    output  [ 5 : 0]    Pj_csr,
    output  [ 5 : 0]    Pd_old_csr,
    output  [ 5 : 0]    Pd_csr,
    output  [13 : 0]    csr_addr_csr,
    output              ready_csr,
    output              RegWr_csr,
    output              csrWr_csr,

    // from ROB
    input   [ 5 : 0]    ptr_old,
    input   [ 5 : 0]    tag_rob         [2 : 0],
    input               csrWr_rob,

    // from CDB
    input               ready_cdb       [4 : 0],
    input               RegWr_cdb       [4 : 0],
    input   [ 5 : 0]    Pd_cdb          [4 : 0],

    // from AGU
    input               ready_Addr,
    input   [ 5 : 0]    tag_rob_Addr,
    input   [31 : 0]    Addr
);

    wire                enable_issue;

    assign  full_queue  =   full_aluq | full_mduq | full_aguq | full_lsuq | full_bruq | full_dirq | full_csrq;

    // input buffer of ptr_old
    reg     [ 5 : 0]    ptr_old_buf;
    
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            ptr_old_buf     <=  '0;
        end
        else begin
            ptr_old_buf     <=  ptr_old;
        end
    end

    ALUQ u_ALUQ (
        .clk                    (clk),
        .rst                    (rst),
        .flush_aluq             (flush_queue),
        .stall_in               (stall_in),
        .full_aluq              (full_aluq),

        .ready_pc               (ready_pc),
        .Pj                     (Pj),
        .valid_Pj               (valid_Pj),
        .Pk                     (Pk),
        .valid_Pk               (valid_Pk),
        .Pd                     (Pd),
        .imm                    (imm),
        .Type                   (Type),
        .Conf                   (Conf),
        .isImm                  (isImm),
        .RegWr                  (RegWr),

        .ready_awake            (ready_alu),
        .Pj_awake               (Pj_alu),
        .Pk_awake               (Pk_alu),
        .Pd_awake               (Pd_alu),
        .imm_awake              (imm_alu),
        .Conf_awake             (Conf_alu),
        .isImm_awake            (isImm_alu),
        .RegWr_awake            (RegWr_alu),
        .tag_rob_awake          (tag_rob_alu),

        // from ROB     
        .ptr_old                (ptr_old_buf),
        .tag_rob                (tag_rob),

        // from CDB     
        .ready_cdb              (ready_cdb),
        .RegWr_cdb              (RegWr_cdb),
        .Pd_cdb                 (Pd_cdb)
    );

    MDUQ u_MDUQ (
        .clk                    (clk),
        .rst                    (rst),
        .flush_mduq             (flush_queue),
        .stall_in               (stall_in),
        .full_mduq              (full_mduq),

        .ready_pc               (ready_pc),
        .Pj                     (Pj),
        .valid_Pj               (valid_Pj),
        .Pk                     (Pk),
        .valid_Pk               (valid_Pk),
        .Pd                     (Pd),
        .Type                   (Type),
        .Conf                   (Conf),
        .RegWr                  (RegWr),

        .ready_awake            (ready_mdu),
        .Pj_awake               (Pj_mdu),
        .Pk_awake               (Pk_mdu),
        .Pd_awake               (Pd_mdu),
        .Conf_awake             (Conf_mdu),
        .RegWr_awake            (RegWr_mdu),
        .tag_rob_awake          (tag_rob_mdu),

        // from ROB     
        .ptr_old                (ptr_old_buf),
        .tag_rob                (tag_rob),

        // from CDB     
        .ready_cdb              (ready_cdb),
        .RegWr_cdb              (RegWr_cdb),
        .Pd_cdb                 (Pd_cdb)
    );      

    AGUQ u_AGUQ (       
        .clk                    (clk),
        .rst                    (rst),
        .flush_aguq             (flush_queue),
        .stall_in               (stall_in),
        .full_aguq              (full_aguq),

        .ready_pc               (ready_pc),
        .Pj                     (Pj),
        .valid_Pj               (valid_Pj),
        .imm                    (imm),
        .Type                   (Type),

        .ready_awake            (ready_agu),
        .Pj_awake               (Pj_agu),
        .imm_awake              (imm_agu),
        .tag_rob_awake          (tag_rob_agu),

        // from ROB     
        .ptr_old                (ptr_old_buf),
        .tag_rob                (tag_rob),

        // from CDB
        .ready_cdb              (ready_cdb),
        .RegWr_cdb              (RegWr_cdb),
        .Pd_cdb                 (Pd_cdb)
    );      

    LSUQ u_LSUQ (       
        .clk                    (clk),
        .rst                    (rst),
        .flush_lsuq             (flush_queue),
        .stall_in               (stall_in),
        .stall_lsuq             (stall_lsuq),
        .full_lsuq              (full_lsuq),

        .ready_pc               (ready_pc),
        .Pd_old                 (Pd_old),
        .valid_Pd_old           (valid_Pd_old),
        .Pd                     (Pd),
        .Type                   (Type),
        .Conf                   (Conf),
        .RegWr                  (RegWr),
        .has_excp               (has_excp),

        .ready_awake            (ready_lsu),
        .Px_awake               (Px_lsu),
        .Addr_awake             (Addr_lsu),
        .Conf_awake             (Conf_lsu),
        .RegWr_awake            (RegWr_lsu),
        .tag_rob_awake          (tag_rob_lsu),
        .has_excp_awake         (has_excp_lsu),

        // from ROB     
        .tag_rob                (tag_rob),

        // from AGU
        .ready_agu              (ready_Addr),
        .tag_rob_agu            (tag_rob_Addr),
        .Addr_agu               (Addr),

        // from CDB     
        .ready_cdb              (ready_cdb),
        .RegWr_cdb              (RegWr_cdb),
        .Pd_cdb                 (Pd_cdb)
    );      

    BRUQ u_BRUQ (       
        .clk                    (clk),
        .rst                    (rst),
        .flush_bruq             (flush_queue),
        .stall_in               (stall_in),
        .full_bruq              (full_bruq),

        .ready_pc               (ready_pc),
        .Pj                     (Pj),
        .valid_Pj               (valid_Pj),
        .Pd_old                 (Pd_old),
        .valid_Pd_old           (valid_Pd_old),
        .Type                   (Type),
        .Conf                   (Conf),    
        .target_predict         (target_predict),
        .imm                    (imm),

        .ready_awake            (ready_bru),
        .Pj_awake               (Pj_bru),
        .Pd_old_awake           (Pd_old_bru),
        .Conf_awake             (Conf_bru),
        .tag_rob_awake          (tag_rob_bru),
        .target_predict_awake   (target_predict_bru),
        .imm_awake              (imm_bru),

        // from ROB
        .ptr_old                (ptr_old_buf),
        .tag_rob                (tag_rob),

        // from CDB     
        .ready_cdb              (ready_cdb),
        .RegWr_cdb              (RegWr_cdb),
        .Pd_cdb                 (Pd_cdb)
    );      

    DIRQ u_DIRQ (       
        .clk                    (clk),
        .rst                    (rst),
        .flush_dirq             (flush_queue),
        .stall_in               (stall_in),
        .full_dirq              (full_dirq),

        .ready_pc               (ready_pc),
        .Type                   (Type),
        .Conf                   (Conf),
        .imm                    (imm),
        .pc                     (pc),    // 专为 JIRL 所设
        .Pd                     (Pd),
        .RegWr                  (RegWr),

        .ready_awake            (ready_dir),
        .imm_awake              (imm_dir),
        .Pd_awake               (Pd_dir),
        .RegWr_awake            (RegWr_dir),
        .Conf_awake             (Conf_dir),
        .tag_rob_awake          (tag_rob_dir),
        .isJIRL_awake           (isJIRL_dir),
        
        // from ROB     
        .tag_rob                (tag_rob)
    );

    CSRQ u_CSRQ (
        .clk                    (clk),
        .rst                    (rst),
        .flush_csrq             (flush_queue),
        .stall_in               (stall_in),
        .full_csrq              (full_csrq),

        .ready_pc               (ready_pc),
        .Type                   (Type),
        .Conf                   (Conf),
        .Pj                     (Pj),
        .valid_Pj               (valid_Pj),
        .Pd_old                 (Pd_old),
        .valid_Pd_old           (valid_Pd_old),
        .Pd                     (Pd),
        .RegWr                  (RegWr),
        .csr_addr               (csr_addr),
        .csrWr                  (csrWr),

        .tag_rob_awake          (tag_rob_csr),
        .Conf_awake             (Conf_csr),
        .Pj_awake               (Pj_csr),
        .Pd_old_awake           (Pd_old_csr),
        .Pd_awake               (Pd_csr),
        .csr_addr_awake         (csr_addr_csr),
        .ready_awake            (ready_csr),
        .RegWr_awake            (RegWr_csr),
        .csrWr_awake            (csrWr_csr),

        // from ROB
        .tag_rob                (tag_rob),
        .csrWr_rob              (csrWr_rob),

        // from CDB
        .ready_cdb              (ready_cdb),
        .RegWr_cdb              (RegWr_cdb),
        .Pd_cdb                 (Pd_cdb)
    );

endmodule