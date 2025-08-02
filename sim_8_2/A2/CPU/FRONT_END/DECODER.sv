`include "../defs.svh"

module DECODER (
    input       [ 1 : 0]    plv,
    input       [31 : 0]    pc          [2 : 0],
    input       [31 : 0]    inst        [2 : 0],
    output  reg [ 4 : 0]    Rj          [2 : 0],
    output  reg [ 4 : 0]    Rk          [2 : 0],
    output  reg [ 4 : 0]    Rd          [2 : 0],
    output  reg [31 : 0]    imm         [2 : 0],
    output  reg [ 2 : 0]    Type        [2 : 0],
    output  reg [ 3 : 0]    Conf        [2 : 0],
    output  reg             isImm       [2 : 0],
    output  reg             RegWr       [2 : 0],
    output  reg             isStore     [2 : 0],
    output  reg             has_excp    [2 : 0],
    output  reg [ 4 : 0]    excp_code   [2 : 0],
    output  reg [13 : 0]    csr_addr    [2 : 0],
    output  reg             csrWr       [2 : 0],
    output  reg             isErtn      [2 : 0],
    output  reg             isIdle      [2 : 0]
);

    generate
        for (genvar i = 0; i < 3; i = i + 1) begin
            always @(*) begin
                casez (inst[i])
                    // ALU
                    `ADD:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `ALU_TYPE; Conf[i] = `ADD_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0;
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `SUB:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `ALU_TYPE; Conf[i] = `SUB_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `SLT:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `ALU_TYPE; Conf[i] = `SLT_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `SLTU:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `ALU_TYPE; Conf[i] = `SLTU_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `NOR:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `ALU_TYPE; Conf[i] = `NOR_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `AND:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `ALU_TYPE; Conf[i] = `AND_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `OR:    begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `ALU_TYPE; Conf[i] = `OR_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `XOR:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `ALU_TYPE; Conf[i] = `XOR_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `SLL:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `ALU_TYPE; Conf[i] = `SLL_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `SRL:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `ALU_TYPE; Conf[i] = `SRL_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `SRA:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `ALU_TYPE; Conf[i] = `SRA_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end

                    `ADDI:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {{20{inst[i][21]}}, inst[i][21:10]};
                            Type[i] = `ALU_TYPE; Conf[i] = `ADD_CONF; isImm[i] = 1; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `SLTI:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {{20{inst[i][21]}}, inst[i][21:10]};
                            Type[i] = `ALU_TYPE; Conf[i] = `SLT_CONF; isImm[i] = 1; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `SLTUI: begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {{20{inst[i][21]}}, inst[i][21:10]};
                            Type[i] = `ALU_TYPE; Conf[i] = `SLTU_CONF; isImm[i] = 1; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `ANDI:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {20'b0, inst[i][21:10]};
                            Type[i] = `ALU_TYPE; Conf[i] = `AND_CONF; isImm[i] = 1; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `ORI:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {20'b0, inst[i][21:10]};
                            Type[i] = `ALU_TYPE; Conf[i] = `OR_CONF; isImm[i] = 1; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `XORI:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {20'b0, inst[i][21:10]};
                            Type[i] = `ALU_TYPE; Conf[i] = `XOR_CONF; isImm[i] = 1; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `SLLI:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {27'b0, inst[i][14:10]};
                            Type[i] = `ALU_TYPE; Conf[i] = `SLL_CONF; isImm[i] = 1; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `SRLI:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {27'b0, inst[i][14:10]};
                            Type[i] = `ALU_TYPE; Conf[i] = `SRL_CONF; isImm[i] = 1; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `SRAI:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {27'b0, inst[i][14:10]};
                            Type[i] = `ALU_TYPE; Conf[i] = `SRA_CONF; isImm[i] = 1; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    
                    // MDU
                    `MUL:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `MDU_TYPE; Conf[i] = `MUL_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `MULH:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `MDU_TYPE; Conf[i] = `MULH_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `MULHU: begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `MDU_TYPE; Conf[i] = `MULHU_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `DIV:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `MDU_TYPE; Conf[i] = `DIV_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `DIVU:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `MDU_TYPE; Conf[i] = `DIVU_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `MOD:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `MDU_TYPE; Conf[i] = `MOD_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `MODU:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = inst[i][14:10]; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `MDU_TYPE; Conf[i] = `MODU_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end

                    // LSU
                    `LDB:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {{20{inst[i][21]}}, inst[i][21:10]};
                            Type[i] = `LSU_TYPE; Conf[i] = `LDB_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `LDH:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {{20{inst[i][21]}}, inst[i][21:10]};
                            Type[i] = `LSU_TYPE; Conf[i] = `LDH_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `LDW:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {{20{inst[i][21]}}, inst[i][21:10]};
                            Type[i] = `LSU_TYPE; Conf[i] = `LDW_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `STB:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {{20{inst[i][21]}}, inst[i][21:10]};
                            Type[i] = `LSU_TYPE; Conf[i] = `STB_CONF; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 1; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `STH:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {{20{inst[i][21]}}, inst[i][21:10]};
                            Type[i] = `LSU_TYPE; Conf[i] = `STH_CONF; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 1; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `STW:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {{20{inst[i][21]}}, inst[i][21:10]};
                            Type[i] = `LSU_TYPE; Conf[i] = `STW_CONF; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 1; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `LDBU:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {{20{inst[i][21]}}, inst[i][21:10]};
                            Type[i] = `LSU_TYPE; Conf[i] = `LDBU_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `LDHU:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {{20{inst[i][21]}}, inst[i][21:10]};
                            Type[i] = `LSU_TYPE; Conf[i] = `LDHU_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end

                    // BRU
                    `BEQ:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `BRU_TYPE; Conf[i] = `BEQ_CONF; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `BNE:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `BRU_TYPE; Conf[i] = `BNE_CONF; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `BLT:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `BRU_TYPE; Conf[i] = `BLT_CONF; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `BGE:   begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `BRU_TYPE; Conf[i] = `BGE_CONF; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `BLTU:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `BRU_TYPE; Conf[i] = `BLTU_CONF; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `BGEU:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `BRU_TYPE; Conf[i] = `BGEU_CONF; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `JIRL:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {{14{inst[i][25]}}, inst[i][25:10],2'b0};
                            Type[i] = `JIRL_TYPE; Conf[i] = `JIRL_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                        
                    // DIR
                    `B:     begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `BL:    begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 5'd1; imm[i] = pc[i] + 4;
                            Type[i] = `DIR_TYPE; Conf[i] = `NONE_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `LU12I: begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = {inst[i][24:5], 12'b0};
                            Type[i] = `DIR_TYPE; Conf[i] = `NONE_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `PCADD: begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = pc[i] + {inst[i][24:5], 12'b0};
                            Type[i] = `DIR_TYPE; Conf[i] = `NONE_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end

                    `CNTID: begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = inst[i][9:5]; imm[i] = 0;
                            Type[i] = `DIR_TYPE; Conf[i] = `CNTID_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `CNTVL: begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `DIR_TYPE; Conf[i] = `CNTVL_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `CNTVH: begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `DIR_TYPE; Conf[i] = `CNTVH_CONF; isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end

                    `BREAK: begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = 1; excp_code[i] = `BRK;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `SYSCL: begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = 1; excp_code[i] = `SYS;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end

                    // CSR
                    `CSR3:  begin
                            Rj[i] = inst[i][9:5]; Rk[i] = 0; Rd[i] = inst[i][4:0]; imm[i] = 0;
                            Type[i] = `CSR_TYPE; Conf[i] = (Rj[i] == 0)? `CSRRD_CONF : (Rj[i] == 1)? `CSRWR_CONF : `CSRXG_CONF;
                                isImm[i] = 0; RegWr[i] = 1; isStore[i] = 0; 
                            has_excp[i] = (plv == 2'b00)? 0 : 1; excp_code[i] = (plv == 2'b00)? 0 : `IPE;
                            csr_addr[i] = inst[i][23:10]; csrWr[i] = (Conf[i] == `CSRRD_CONF)? 0 : 1;
                                isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `ERTN:  begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = `CSR_TYPE; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = (plv == 2'b00)? 0 : 1; excp_code[i] = (plv == 2'b00)? 0 : `IPE;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 1; isIdle[i] = 0;
                            end
                        //     尚未实现
                    `IDLE:  begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = (plv == 2'b00)? 0 : 1; excp_code[i] = (plv == 2'b00)? 0 : `IPE;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 1;
                            end

                    // 不打算实现
                    `CACOP: begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = (plv == 2'b00)? 0 : 1; excp_code[i] = (plv == 2'b00)? 0 : `IPE;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `TLBSH: begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = (plv == 2'b00)? 0 : 1; excp_code[i] = (plv == 2'b00)? 0 : `IPE;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `TLBRD: begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = (plv == 2'b00)? 0 : 1; excp_code[i] = (plv == 2'b00)? 0 : `IPE;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `TLBWR: begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = (plv == 2'b00)? 0 : 1; excp_code[i] = (plv == 2'b00)? 0 : `IPE;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `TLBFL: begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = (plv == 2'b00)? 0 : 1; excp_code[i] = (plv == 2'b00)? 0 : `IPE;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `INVTLB:begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = (plv == 2'b00)? 0 : 1; excp_code[i] = (plv == 2'b00)? 0 : `IPE;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `LL:    begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `SC:    begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `PRELD: begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `DBAR:  begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `IBAR:  begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                    `NOP:   begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0; 
                            has_excp[i] = 0; excp_code[i] = 0;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end

                    // 不存在的指令
                    default:begin
                            Rj[i] = 0; Rk[i] = 0; Rd[i] = 0; imm[i] = 0;
                            Type[i] = 0; Conf[i] = 0; isImm[i] = 0; RegWr[i] = 0; isStore[i] = 0;
                            has_excp[i] = 1; excp_code[i] = `INE;
                            csr_addr[i] = 0; csrWr[i] = 0; isErtn[i] = 0; isIdle[i] = 0;
                            end
                endcase
            end
        end
    endgenerate

endmodule