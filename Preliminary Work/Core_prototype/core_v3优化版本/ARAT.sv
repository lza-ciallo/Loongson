module ARAT (
    input                   clk,
    input                   rst,
    // ROB 退休
    input                   ready_ret   [2 : 0],
    input                   excep_ret   [2 : 0],
    input       [ 1 : 0]    Type_ret    [2 : 0],
    input       [ 4 : 0]    Pw_ret      [2 : 0],
    input       [ 2 : 0]    Rw_ret      [2 : 0],
    // 精确异常恢复
    output  reg [ 4 : 0]    ARAT_P_list [7 : 0],
    output  reg [31 : 0]    ARAT_freelist
);

    wire        [ 4 : 0]    Pw_old      [2 : 0];

    integer i;
    genvar  gvi;

    generate
        for (gvi = 0; gvi < 3; gvi = gvi + 1) begin
            assign  Pw_old[gvi]   =   ARAT_P_list[Rw_ret[gvi]];
        end
    endgenerate

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                ARAT_P_list[i]  <=  i;
            end
            ARAT_freelist       <=  32'hffff_ff00;
        end
        else begin
            if (ready_ret[0] == 1 && excep_ret[0] == 0 && Type_ret[0] != 2'b11) begin
                ARAT_P_list[Rw_ret[0]]              <=  Pw_ret[0];
                ARAT_freelist[Pw_ret[0]]            <=  0;
                ARAT_freelist[Pw_old[0]]            <=  1;
                if (ready_ret[1] == 1 && excep_ret[1] == 0 && Type_ret[1] != 2'b11) begin
                    ARAT_P_list[Rw_ret[1]]          <=  Pw_ret[1];
                    ARAT_freelist[Pw_ret[1]]        <=  0;
                    ARAT_freelist[Pw_old[1]]        <=  1;
                    if (ready_ret[2] == 1 && excep_ret[2] == 0 && Type_ret[2] != 2'b11) begin
                        ARAT_P_list[Rw_ret[2]]      <=  Pw_ret[2];
                        ARAT_freelist[Pw_ret[2]]    <=  0;
                        ARAT_freelist[Pw_old[2]]    <=  1;
                    end
                end
            end
        end
    end

endmodule