module AGU (
    input                   clk,
    input                   rst,
    input                   flush,
    input                   freeze_back,
    // 输入
    input                   valid_agu,
    input       [15 : 0]    busA_agu,
    input       [ 4 : 0]    Imm,
    input       [ 4 : 0]    tag_ROB_agu,
    // 输出
    output  reg             valid_Addr_agu,
    output  reg [15 : 0]    Addr_agu,
    output  reg [ 4 : 0]    tag_ROB_Result_agu
);

    wire    [15 : 0]    ExtImm;

    assign  ExtImm  =   {{11{Imm[4]}}, Imm};

    always @(posedge clk or negedge rst) begin
        if (rst) begin
            valid_Addr_agu          <=  '0;
            tag_ROB_Result_agu      <=  '0;
            Addr_agu                <=  '0;
        end
        else begin
            if (flush) begin
                valid_Addr_agu      <=  '0;
                tag_ROB_Result_agu  <=  '0;
                Addr_agu            <=  '0;
            end
            else if (freeze_back) begin
                valid_Addr_agu      <=  valid_Addr_agu;
                tag_ROB_Result_agu  <=  tag_ROB_Result_agu;
                Addr_agu            <=  Addr_agu;
            end
            else begin
                valid_Addr_agu      <=  valid_agu;
                tag_ROB_Result_agu  <=  tag_ROB_agu;
                Addr_agu            <=  busA_agu + ExtImm;
            end
        end
    end

endmodule