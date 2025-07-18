module DATA_MEM (
    input   clk,
    input   rst,
    input   MemWr,
    input   [31 : 0]    Addr,
    input   [31 : 0]    data_in,
    output  [31 : 0]    data_out
);

    wire    [7 : 0]     Addr_real;
    assign  Addr_real = Addr[9 : 2];

    // wire    ena;
    // assign  ena = 1;

    // wire    clk_n;
    // assign  clk_n = ~clk;

    // BRAM_DATA u_BRAM_DATA (
    //     .clka(clk_n),       // input wire clka
    //     .ena(ena),          // input wire ena
    //     .wea(MemWr),        // input wire [0 : 0] wea
    //     .addra(Addr_real),  // input wire [7 : 0] addra
    //     .dina(data_in),     // input wire [31 : 0] dina
    //     .douta(data_out)    // output wire [31 : 0] douta
    // );

    reg     [31 : 0]    DataMem [255 : 0];

    integer i;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            ////////////////////////////////////// type your initial data here //////////////////////////////////////

            DataMem[0]  <= 32'h0000_0003;
            DataMem[1]  <= 32'h0000_0004;
            DataMem[2]  <= 32'h0000_0005;
            DataMem[3]  <= 32'h0000_0004;
            DataMem[4]  <= 32'h0000_0009;
            DataMem[5]  <= 32'h0000_0007;
            DataMem[6]  <= 32'h0000_000F;
            DataMem[7]  <= 32'h0000_0009;
            DataMem[8]  <= 32'h0000_0002;
            DataMem[9]  <= 32'h0000_0001;
            DataMem[10] <= 32'h0000_0000;
            DataMem[11] <= 32'h0000_0002;
            DataMem[12] <= 32'h0000_0000;
            DataMem[13] <= 32'h0000_0001;
            DataMem[14] <= 32'h0000_0002;
            DataMem[15] <= 32'h0000_0004;

            DataMem[16] <= 32'h0000_0001;
            DataMem[17] <= 32'h0000_0004;
            DataMem[18] <= 32'h0000_0000;
            DataMem[19] <= 32'h0000_000C;
            DataMem[20] <= 32'h0000_000B;
            DataMem[21] <= 32'h0000_0009;
            DataMem[22] <= 32'h0000_0000;
            DataMem[23] <= 32'h0000_000B;
            DataMem[24] <= 32'h0000_0008;
            DataMem[25] <= 32'h0000_0002;
            DataMem[26] <= 32'h0000_000C;
            DataMem[27] <= 32'h0000_0002;
            DataMem[28] <= 32'h0000_000B;
            DataMem[29] <= 32'h0000_000A;
            DataMem[30] <= 32'h0000_0000;
            DataMem[31] <= 32'h0000_000A;
            DataMem[32] <= 32'h0000_000C;
            DataMem[33] <= 32'h0000_0000;
            DataMem[34] <= 32'h0000_0001;
            DataMem[35] <= 32'h0000_0009;

            for (i = 36; i < 200; i = i + 1) begin  // for writing in
                DataMem[i] <= 32'h0000_0000;
            end

            DataMem[200] <= 32'h0000_003f;          // BCD查找表
            DataMem[201] <= 32'h0000_0006; 
            DataMem[202] <= 32'h0000_005b; 
            DataMem[203] <= 32'h0000_004f; 
            DataMem[204] <= 32'h0000_0066; 
            DataMem[205] <= 32'h0000_006d; 
            DataMem[206] <= 32'h0000_007d; 
            DataMem[207] <= 32'h0000_0007; 
            DataMem[208] <= 32'h0000_007f; 
            DataMem[209] <= 32'h0000_006f; 
            DataMem[210] <= 32'h0000_0077; 
            DataMem[211] <= 32'h0000_007c; 
            DataMem[212] <= 32'h0000_0039; 
            DataMem[213] <= 32'h0000_005e; 
            DataMem[214] <= 32'h0000_0079; 
            DataMem[215] <= 32'h0000_0071;

            /////////////////////////////////////////////////////////////////////////////////////////////////////////
            for (i = 216; i < 256; i = i + 1) begin
                DataMem[i] <= 32'h0000_0000;
            end
        end
        else if (MemWr && Addr_real < 256) begin
            DataMem[Addr_real] <= data_in;
        end
    end

    assign  data_out = (Addr_real < 256)? DataMem[Addr_real] : 32'h0000_0000;

endmodule


module  LED (
    input   clk,
    input   rst,
    input   MemWr,
    input   [31 : 0]    Addr,
    input   [31 : 0]    data_in,
    output  [7 : 0]     leds,
    output  [3 : 0]     enable
);

    reg     [31 : 0]    data_reg;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            data_reg <= 32'h0000_0000;
        end
        else if (MemWr && Addr == 32'h4000_0010) begin
            data_reg <= data_in;
        end
    end

    assign  leds = data_reg[7 : 0];
    assign  enable = data_reg[11 : 8];

endmodule


module  MUL_UNIT_B #(
    // parameter   BW_MUL  =   160
    parameter   BW_MUL  =   96
)(
    input   [BW_MUL - 1 : 0]    half_Result,
    output  [31 : 0]            Result
);

    // wire    [15 : 0]    partial_sum [9 : 0];

    // assign  {partial_sum[9], partial_sum[8], partial_sum[7], partial_sum[6], partial_sum[5],
    //         partial_sum[4], partial_sum[3], partial_sum[2], partial_sum[1], partial_sum[0]} = half_Result;

    // assign  Result = partial_sum[0] +
    //         ((partial_sum[1] + partial_sum[2]) << 8) +
    //         ((partial_sum[3] + partial_sum[4] + partial_sum[5]) << 16) +
    //         ((partial_sum[6] + partial_sum[7] + partial_sum[8] + partial_sum[9]) << 24);

    wire    [31 : 0]    partial_sum [2 : 0];

    assign  {partial_sum[2], partial_sum[1], partial_sum[0]} = half_Result;

    assign  Result = partial_sum[0] + ((partial_sum[1] + partial_sum[2]) << 16);

endmodule


module MEM #(
    // parameter   BW_MUL  =   160
    parameter   BW_MUL  =   96
)(
    input               clk,
    input               rst,
    input               MemWr,
    input   [1 : 0]     MemtoReg,
    input   [31 : 0]    Result,
    input   [31 : 0]    busB,
    input   [31 : 0]    LuiImm32,
    input   [31 : 0]    pc,
    output  [7 : 0]     leds,
    output  [3 : 0]     enable,
    output reg [31 : 0] busW,
    input  [BW_MUL-1:0] half_Result,
    input               Mul
);

    wire    [31 : 0]    data_out;

    wire    [31 : 0]    Result_mul;

    always @(*) begin
        case (MemtoReg)
            3:          busW = LuiImm32;
            2:          busW = pc + 8;
            1:          busW = data_out; 
            default:    busW = (Mul == 1)? Result_mul : Result;
        endcase
    end

    DATA_MEM u_DATA_MEM (
        .clk(clk),
        .rst(rst),
        .MemWr(MemWr),
        .Addr(Result),
        .data_in(busB),
        .data_out(data_out)
    );

    LED u_LED (
        .clk(clk),
        .rst(rst),
        .MemWr(MemWr),
        .Addr(Result),
        .data_in(busB),
        .leds(leds),
        .enable(enable)
    );

    MUL_UNIT_B #(
        .BW_MUL(BW_MUL)
    ) u_MUL_UNIT_B (
        .half_Result(half_Result),
        .Result(Result_mul)
    );

endmodule