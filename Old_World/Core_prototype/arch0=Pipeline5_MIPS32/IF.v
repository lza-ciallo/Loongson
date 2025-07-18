module PC (
    input   clk,
    input   rst,
    input   stall,
    input   Branch,
    input   Jump,
    input       [31 : 0]    BranchAddr,
    input       [31 : 0]    JumpAddr,
    output  reg [31 : 0]    pc
);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            pc <= 32'h0040_0000 - 4;
        end
        else if (stall) begin
            pc <= pc;
        end
        else if (Branch) begin
            pc <= BranchAddr;
        end
        else if (Jump) begin
            pc <= JumpAddr;
        end
        else begin
            pc <= pc + 4;
        end
    end

endmodule


module INST_MEM (
    input               clk,
    input   [31 : 0]    pc,
    // output  [31 : 0]    inst
    output reg [31 : 0] inst
);

    wire    [6 : 0]     Addr_real;
    assign  Addr_real = pc[8 : 2];

    // wire    ena;
    // assign  ena = 1;

    // wire    clk_n;
    // assign  clk_n = ~clk;

    // ROM_INST u_ROM_INST (
    //     .clka(clk_n),       // input wire clka
    //     .ena(ena),          // input wire ena
    //     .addra(Addr_real),  // input wire [6 : 0] addra
    //     .douta(inst)        // output wire [31 : 0] douta
    // );

    always @(*) begin
        case (Addr_real)
            ////////////////////////////////////// type your asm code here //////////////////////////////////////

            7'd0:    inst = 32'h2008_0000;
            7'd1:    inst = 32'h8d10_0000;
            7'd2:    inst = 32'h8d11_0004;
            7'd3:    inst = 32'h8d12_0008;
            7'd4:    inst = 32'h8d13_000c;
            7'd5:    inst = 32'h2114_0010;
            7'd6:    inst = 32'h0013_a880;
            7'd7:    inst = 32'h02b4_a820;
            7'd8:    inst = 32'h0013_b0c0;
            7'd9:    inst = 32'h02d4_b020;
            7'd10:   inst = 32'h2217_0001;
            7'd11:   inst = 32'h0017_b880;
            7'd12:   inst = 32'h02f6_b820;
            7'd13:   inst = 32'h2008_0000;
            7'd14:   inst = 32'h7212_4802;
            7'd15:   inst = 32'h200a_0090;
            7'd16:   inst = 32'h0008_5880;
            7'd17:   inst = 32'h016a_5820;
            7'd18:   inst = 32'had60_0000;
            7'd19:   inst = 32'h2108_0001;
            7'd20:   inst = 32'h0109_082a;
            7'd21:   inst = 32'h1420_fffa;
            7'd22:   inst = 32'h2008_0000;
            7'd23:   inst = 32'h2009_0090;
            7'd24:   inst = 32'h0008_5880;
            7'd25:   inst = 32'h0176_5820;
            7'd26:   inst = 32'h8d6c_0000;
            7'd27:   inst = 32'h8d6d_0004;
            7'd28:   inst = 32'h218a_0000;
            7'd29:   inst = 32'h000a_5880;
            7'd30:   inst = 32'h0175_5820;
            7'd31:   inst = 32'h8d6e_0000;
            7'd32:   inst = 32'h000a_5880;
            7'd33:   inst = 32'h0174_5820;
            7'd34:   inst = 32'h8d6f_0000;
            7'd35:   inst = 32'h2018_0000;
            7'd36:   inst = 32'h71d2_5802;
            7'd37:   inst = 32'h0178_5820;
            7'd38:   inst = 32'h000b_5880;
            7'd39:   inst = 32'h0177_5820;
            7'd40:   inst = 32'h8d62_0000;
            7'd41:   inst = 32'h704f_1002;
            7'd42:   inst = 32'h7112_5802;
            7'd43:   inst = 32'h0178_5820;
            7'd44:   inst = 32'h000b_5880;
            7'd45:   inst = 32'h0169_5820;
            7'd46:   inst = 32'h8d79_0000;
            7'd47:   inst = 32'h0322_c820;
            7'd48:   inst = 32'had79_0000;
            7'd49:   inst = 32'h2318_0001;
            7'd50:   inst = 32'h0312_082a;
            7'd51:   inst = 32'h1420_fff0;
            7'd52:   inst = 32'h214a_0001;
            7'd53:   inst = 32'h014d_082a;
            7'd54:   inst = 32'h1420_ffe6;
            7'd55:   inst = 32'h2108_0001;
            7'd56:   inst = 32'h0110_082a;
            7'd57:   inst = 32'h1420_ffde;
            
            7'd58:   inst = 32'h2017_4000;
            7'd59:   inst = 32'h0017_bc00;
            7'd60:   inst = 32'h22f7_0010;
            7'd61:   inst = 32'h2019_3e80;
            7'd62:   inst = 32'h0000_0000;
            7'd63:   inst = 32'h2018_00fa;
            7'd64:   inst = 32'h2009_0000;
            7'd65:   inst = 32'h2008_0090;
            7'd66:   inst = 32'h7212_8802;
            7'd67:   inst = 32'h1131_002c;
            7'd68:   inst = 32'h8d0b_0000;
            7'd69:   inst = 32'h0018_a820;
            7'd70:   inst = 32'h316a_000f;
            7'd71:   inst = 32'h000a_5080;
            7'd72:   inst = 32'h8d4c_0320;
            7'd73:   inst = 32'h218d_0100;
            7'd74:   inst = 32'haeed_0000;
            7'd75:   inst = 32'h0019_b020;
            7'd76:   inst = 32'h22d6_ffff;
            7'd77:   inst = 32'h12c0_0001;
            7'd78:   inst = 32'h0810_004c;
            7'd79:   inst = 32'h316a_00f0;
            7'd80:   inst = 32'h000a_5082;
            7'd81:   inst = 32'h8d4c_0320;
            7'd82:   inst = 32'h218d_0200;
            7'd83:   inst = 32'haeed_0000;
            7'd84:   inst = 32'h0019_b020;
            7'd85:   inst = 32'h22d6_ffff;
            7'd86:   inst = 32'h12c0_0001;
            7'd87:   inst = 32'h0810_0055;
            7'd88:   inst = 32'h316a_0f00;
            7'd89:   inst = 32'h000a_5182;
            7'd90:   inst = 32'h8d4c_0320;
            7'd91:   inst = 32'h218d_0400;
            7'd92:   inst = 32'haeed_0000;
            7'd93:   inst = 32'h0019_b020;
            7'd94:   inst = 32'h22d6_ffff;
            7'd95:   inst = 32'h12c0_0001;
            7'd96:   inst = 32'h0810_005e;
            7'd97:   inst = 32'h316a_f000;
            7'd98:   inst = 32'h000a_5282;
            7'd99:   inst = 32'h8d4c_0320;
            7'd100:  inst = 32'h218d_0800;
            7'd101:  inst = 32'haeed_0000;
            7'd102:  inst = 32'h0019_b020;
            7'd103:  inst = 32'h22d6_ffff;
            7'd104:  inst = 32'h12c0_0001;
            7'd105:  inst = 32'h0810_0067;
            7'd106:  inst = 32'h22b5_ffff;
            7'd107:  inst = 32'h12a0_0001;
            7'd108:  inst = 32'h0810_0046;
            7'd109:  inst = 32'h2108_0004;
            7'd110:  inst = 32'h2129_0001;
            7'd111:  inst = 32'h0810_0043;
            7'd112:  inst = 32'h2008_0f40;
            7'd113:  inst = 32'haee8_0000;
            7'd114:  inst = 32'h0810_0072;

            /////////////////////////////////////////////////////////////////////////////////////////////////////
            default:    inst = 32'h0000_0000;
        endcase
    end

endmodule


module IF (
    input   clk,
    input   rst,
    input   stall,
    input   Branch,
    input   Jump,
    input   [31 : 0]    BranchAddr,
    input   [31 : 0]    JumpAddr,
    output  [31 : 0]    pc,
    output  [31 : 0]    inst
);

    PC u_PC (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .Branch(Branch),
        .Jump(Jump),
        .BranchAddr(BranchAddr),
        .JumpAddr(JumpAddr),
        .pc(pc)
    );

    INST_MEM u_INST_MEM (
        .clk(clk),
        .pc(pc),
        .inst(inst)
    );

endmodule