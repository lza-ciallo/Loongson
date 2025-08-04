module IFREG (
    input                   clk,
    input                   rst,
    input                   flush_ifr,
    input                   stall_ifr,
    input                   full_ififo,
    input                   stall_if_request,
    input                   Jump,
    input                   Miss,
    input                   flush_back,

    input       [31 : 0]    pc                  [3 : 0],
    input                   Hit                 [3 : 0],
    input                   Predict             [3 : 0],
    input       [31 : 0]    target_predict      [3 : 0],
    input                   has_excp            [3 : 0],
    input       [ 4 : 0]    excp_code           [3 : 0],
    output  reg             hint,
    output  reg [31 : 0]    pc_out              [3 : 0],
    output  reg             Hit_out             [3 : 0],
    output  reg             Predict_out         [3 : 0],
    output  reg [31 : 0]    target_predict_out  [3 : 0],
    output  reg             has_excp_out        [3 : 0],
    output  reg [ 4 : 0]    excp_code_out       [3 : 0],

    input       [31 : 0]    inst                [3 : 0],
    input                   find_inst           [3 : 0],
    output  reg [31 : 0]    inst_out            [3 : 0],
    output  reg             find_inst_out       [3 : 0],
    output  reg             cache_lock
);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            inst_out        <=  inst;
            find_inst_out   <=  find_inst;
            cache_lock      <=  0;
        end
        else begin
            if (~(flush_back | ((Jump | Miss) & ~full_ififo))) begin
                if (!cache_lock) begin
                    inst_out        <=  inst;
                    find_inst_out   <=  find_inst;
                end
                else begin
                    inst_out        <=  inst_out;
                    find_inst_out   <=  find_inst_out;
                end
                if (full_ififo) begin
                    cache_lock  <=  1;
                end
                else if (~full_ififo) begin
                    cache_lock  <=  0;
                end
                else begin
                    cache_lock  <=  cache_lock;
                end
            end
            else begin
                inst_out        <=  inst;
                find_inst_out   <=  find_inst;
                cache_lock      <=  0;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (integer i = 0; i < 4; i = i + 1) begin
                pc_out[i]                   <=  '0;
                Hit_out[i]                  <=  '0;
                Predict_out[i]              <=  '0;
                target_predict_out[i]       <=  '0;
                has_excp_out[i]             <=  '0;
                excp_code_out[i]            <=  '0;
            end
            hint                            <=  0;
        end
        else begin
            if (flush_back | ((Jump | Miss) & ~full_ififo)) begin
                for (integer i = 0; i < 4; i = i + 1) begin
                    pc_out[i]               <=  '0;
                    Hit_out[i]              <=  '0;
                    Predict_out[i]          <=  '0;
                    target_predict_out[i]   <=  '0;
                    has_excp_out[i]         <=  '0;
                    excp_code_out[i]        <=  '0;
                end
                hint                        <=  0;
            end
            else if (stall_ifr) begin
                pc_out                      <=  pc_out;
                Hit_out                     <=  Hit_out;
                Predict_out                 <=  Predict_out;
                target_predict_out          <=  target_predict_out;
                has_excp_out                <=  has_excp_out;
                excp_code_out               <=  excp_code_out;
                hint                        <=  hint;
            end
            else if (stall_if_request) begin
                for (integer i = 0; i < 4; i = i + 1) begin
                    pc_out[i]               <=  '0;
                    Hit_out[i]              <=  '0;
                    Predict_out[i]          <=  '0;
                    target_predict_out[i]   <=  '0;
                    has_excp_out[i]         <=  '0;
                    excp_code_out[i]        <=  '0;
                end
                hint                        <=  0;
            end
            else begin
                pc_out                      <=  pc;
                Hit_out                     <=  Hit;
                Predict_out                 <=  Predict;
                target_predict_out          <=  target_predict;
                has_excp_out                <=  has_excp;
                excp_code_out               <=  excp_code;
                hint                        <=  1;
            end
        end
    end

endmodule