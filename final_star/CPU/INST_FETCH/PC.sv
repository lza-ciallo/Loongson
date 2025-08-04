`include "../defs.svh"

module PC (
    input               clk,
    input               rst,
    input               flush_pc_branch,
    input               flush_pc_excp,
    input               flush_pc_ertn,
    input               flush_pc_idle,
    input               stall_pc,
    input               full_ififo,

    output  [31 : 0]    pc  [3 : 0],

    // from ROB
    input               Branch_rob,
    input   [31 : 0]    target_rob,
    input   [31 : 0]    pc_rob,
    // from predecoder
    input               Jump,
    input   [31 : 0]    target_jump,
    input               Miss,
    input   [31 : 0]    pc_miss,
    // from BPU
    input               Predict,
    input   [31 : 0]    target_branch,
    // from CSR
    input   [31 : 0]    target_excp,
    input   [31 : 0]    target_ertn
);

    reg     [31 : 0]    pc_r;

    assign  pc[0]   =   pc_r;
    assign  pc[1]   =   pc_r + 4;
    assign  pc[2]   =   pc_r + 8;
    assign  pc[3]   =   pc_r + 12;



    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            pc_r    <=  `START_PC;
        end
        else begin
            pc_r    <=  flush_pc_branch?    (Branch_rob? target_rob : pc_rob + 4) :
                        flush_pc_excp?      target_excp     :
                        flush_pc_ertn?      target_ertn     :
                        flush_pc_idle?      pc_rob + 4      :
                        full_ififo?         pc_r            :
                        Jump?               target_jump     :
                        Miss?               pc_miss         :
                        stall_pc?           pc_r            :
                        Predict?            target_branch   : pc_r + 16;
        end
    end

endmodule