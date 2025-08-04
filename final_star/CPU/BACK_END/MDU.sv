`include "../defs.svh"

module MDU (
    input                   clk,
    input                   rst,
    input                   flush_back,

    input       [31 : 0]    busA,
    input       [31 : 0]    busB,
    input       [ 3 : 0]    Conf,
    output  reg [31 : 0]    Result_r,

    input       [ 5 : 0]    Pd,
    input                   ready,
    input                   RegWr,
    input       [ 5 : 0]    tag_rob,

    output  reg [ 5 : 0]    Pd_r,
    output  reg             ready_r,
    output  reg             RegWr_r,
    output  reg [ 5 : 0]    tag_rob_r
);

    localparam  MUL_TIME        =   1;
    localparam  DIV_TIME        =   16;
    localparam  BUFFER_DEPTH    =   32;
    // 需要手动配置 ptr 宽度

    wire    [31 : 0]    Result_mul;
    wire    [ 5 : 0]    Pd_mul;
    wire                ready_mul;
    wire                RegWr_mul;
    wire    [ 5 : 0]    tag_rob_mul;
    wire                is_mul;

    wire    [31 : 0]    Result_divmod;
    wire    [ 5 : 0]    Pd_divmod;
    wire                ready_divmod;
    wire                RegWr_divmod;
    wire    [ 5 : 0]    tag_rob_divmod;
    wire                is_divmod;

    typedef struct packed {
        reg [31 : 0]    Result;
        reg [ 5 : 0]    Pd;
        reg             ready;
        reg             RegWr;
        reg [ 5 : 0]    tag_rob;
    } buffer_entry;

    buffer_entry    buffer  [BUFFER_DEPTH-1 : 0];
    reg     [ 4 : 0]    ptr_old;
    reg     [ 4 : 0]    ptr_young;

    wire    [ 4 : 0]    ptr_write   [1 : 0];
    assign  ptr_write[0]    =   ptr_young;
    assign  ptr_write[1]    =   ptr_young + 1;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (integer i = 0; i < BUFFER_DEPTH; i = i + 1) begin
                buffer[i]       <=  '0;
            end
            ptr_old             <=  '0;
            ptr_young           <=  '0;
            {Result_r, Pd_r, ready_r, RegWr_r, tag_rob_r}       <=  '0;
        end
        else begin
            if (flush_back) begin
                for (integer i = 0; i < BUFFER_DEPTH; i = i + 1) begin
                    buffer[i]   <=  '0;
                end
                ptr_old         <=  '0;
                ptr_young       <=  '0;
                {Result_r, Pd_r, ready_r, RegWr_r, tag_rob_r}   <=  '0;
            end
            else begin
                // pop in 2
                case ({ready_divmod & RegWr_divmod & is_divmod, ready_mul & RegWr_mul & is_mul})
                    2'b01:  begin
                        buffer[ptr_write[0]]    <=  {Result_mul, Pd_mul, ready_mul, RegWr_mul, tag_rob_mul};
                        ptr_young               <=  ptr_young + 1;
                    end
                    2'b10:  begin
                        buffer[ptr_write[0]]    <=  {Result_divmod, Pd_divmod, ready_divmod, RegWr_divmod, tag_rob_divmod};
                        ptr_young               <=  ptr_young + 1;
                    end
                    2'b11:  begin
                        buffer[ptr_write[0]]    <=  {Result_mul, Pd_mul, ready_mul, RegWr_mul, tag_rob_mul};
                        buffer[ptr_write[1]]    <=  {Result_divmod, Pd_divmod, ready_divmod, RegWr_divmod, tag_rob_divmod};
                        ptr_young               <=  ptr_young + 2;
                    end
                    default:    ptr_young       <=  ptr_young;
                endcase
                // pop out 1
                if (buffer[ptr_old].ready == 1) begin
                    {Result_r, Pd_r, ready_r, RegWr_r, tag_rob_r}   <=  buffer[ptr_old];
                    buffer[ptr_old]                                 <=  '0;
                    ptr_old                                         <=  ptr_old + 1;
                end
                else begin
                    {Result_r, Pd_r, ready_r, RegWr_r, tag_rob_r}   <=  '0;
                end
            end
        end
    end

    mul_wrapper #(
        .MUL_TIME       (MUL_TIME)
    ) u_mul (
        .clk            (clk),
        .rst            (rst),
        .flush_back     (flush_back),

        .busA           (busA),
        .busB           (busB),
        .Conf           (Conf),
        .Result_mul     (Result_mul),

        .Pd             (Pd),
        .ready          (ready),
        .RegWr          (RegWr),
        .tag_rob        (tag_rob),

        .Pd_mul         (Pd_mul),
        .ready_mul      (ready_mul),
        .RegWr_mul      (RegWr_mul),
        .tag_rob_mul    (tag_rob_mul),
        .is_mul         (is_mul)
    );

    div_wrapper #(
        .DIV_TIME       (DIV_TIME)
    ) u_div (
        .clk            (clk),
        .rst            (rst),
        .flush_back     (flush_back),

        .busA           (busA),
        .busB           (busB),
        .Conf           (Conf),
        .Result_divmod  (Result_divmod),

        .Pd             (Pd),
        .ready          (ready),
        .RegWr          (RegWr),
        .tag_rob        (tag_rob),

        .Pd_divmod      (Pd_divmod),
        .ready_divmod   (ready_divmod),
        .RegWr_divmod   (RegWr_divmod),
        .tag_rob_divmod (tag_rob_divmod),
        .is_divmod      (is_divmod)
    );

    // 疑似 $signed 不能正确处理负数除法
    // reg         [31 : 0]    Result;

    // wire signed [63 : 0]    mul_signed;
    // wire        [63 : 0]    mul_unsigned;

    // assign  mul_signed      =   $signed(busA) * $signed(busB);
    // assign  mul_unsigned    =   $unsigned(busA) * $unsigned(busB);

    // // just simulate <*,/,%> in 1 cycle here
    // always @(*) begin
    //     case (Conf)
    //         `MUL_CONF:      Result  =   mul_signed[31 : 0];
    //         `MULH_CONF:     Result  =   mul_signed[63 : 32];
    //         `MULHU_CONF:    Result  =   mul_unsigned[63 : 32];
    //         `DIV_CONF:      Result  =   (busB == 0)? 32'hffff_ffff : $signed(busA) / $signed(busB);
    //         `DIVU_CONF:     Result  =   (busB == 0)? 32'hffff_ffff : $unsigned(busA) / $unsigned(busB);
    //         `MOD_CONF:      Result  =   (busB == 0)? 32'hffff_ffff : $signed(busA) % $signed(busB);
    //         `MODU_CONF:     Result  =   (busB == 0)? 32'hffff_ffff : $unsigned(busA) % $unsigned(busB);
    //         default:        Result  =   '0;
    //     endcase
    // end

    // always @(posedge clk or negedge rst) begin
    //     if (!rst) begin
    //         {Result_r, Pd_r, ready_r, RegWr_r, tag_rob_r}       <=  '0;
    //     end
    //     else begin
    //         if (flush_back) begin
    //             {Result_r, Pd_r, ready_r, RegWr_r, tag_rob_r}   <=  '0;
    //         end
    //         else begin
    //             {Result_r, Pd_r, ready_r, RegWr_r, tag_rob_r}   <=  {Result, Pd, ready, RegWr, tag_rob};
    //         end
    //     end
    // end

endmodule