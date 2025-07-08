module DATA_MEM (
    input                   clk,
    input                   rst,
    input                   flush,
    input                   freeze_back,
    output                  full_FIFO,
    // 输入
    input                   valid_ls,
    input                   mode,
    input       [15 : 0]    busX,
    input       [15 : 0]    Addr,
    input       [ 4 : 0]    tag_ROB_ls,
    input       [ 4 : 0]    Px,
    // 输出
    output  reg             valid_Result_ls,
    output  reg             mode_ls,    // mode 输入, mode_ls 输出
    output  reg [ 4 : 0]    tag_ROB_Result_ls,
    output  reg [15 : 0]    Result_ls,
    output  reg [ 4 : 0]    Pw_Result_ls,
    // ROB 退休
    input                   ready_ret   [2 : 0],
    input                   excep_ret   [2 : 0],
    input       [ 1 : 0]    Type_ret    [2 : 0]
);

    typedef struct packed {
        reg     [15 : 0]    data;
        reg     [15 : 0]    Addr;
    } fifo_entry;

    fifo_entry          fifo            [ 15 : 0];

    reg     [15 : 0]    valid_fifo;

    reg     [15 : 0]    mem_data        [255 : 0];
    
    reg     [ 3 : 0]    ptr_old;
    reg     [ 3 : 0]    ptr_young;

    reg     [15 : 0]    fifo_data;
    reg                 find_in_fifo;
    reg                 find_stop;

    wire    [ 2 : 0]    ready_ret_wire;
    wire    [ 2 : 0]    excep_ret_wire;

    wire    [ 3 : 0]    ptr_old_wire    [  2 : 0];

    integer     i, j, k, count;

    // full_FIFO 判定
    assign  full_FIFO   =   (valid_fifo == 16'hffff)? 1 : 0;

    // 在 FIFO 中尝试搜索对应条目
    always @(*) begin
        fifo_data       =   0;
        find_in_fifo    =   0;
        find_stop       =   0;
        for (j = 15; j >= 0; j = j - 1) begin
            k = (j + ptr_old >= 16)? j + ptr_old - 16 : j + ptr_old;
            if (find_stop == 0 && valid_fifo[k] == 1) begin
                if (fifo[k].Addr == Addr) begin
                    fifo_data       =   fifo[k].data;
                    find_in_fifo    =   1;
                    find_stop       =   1;
                end
            end
        end
    end

    // 退休的 save 计数
    assign  ptr_old_wire[0] =   ptr_old;
    assign  ptr_old_wire[1] =   ptr_old + 1;
    assign  ptr_old_wire[2] =   ptr_old + 2;

    assign  ready_ret_wire  =   {ready_ret[2], ready_ret[1], ready_ret[0]};
    assign  excep_ret_wire  =   {excep_ret[2], excep_ret[1], excep_ret[0]};

    always @(*) begin
        casez (ready_ret_wire & ~excep_ret_wire)
            3'b?01: count = (Type_ret[0] == 2'b11)? 1 : 0;
            3'b011: begin
                    count = (Type_ret[0] == 2'b11)? ((Type_ret[1] == 2'b11)? 2 : 1):
                                                    ((Type_ret[1] == 2'b11)? 1 : 0);
                    end
            3'b111: begin
                    count = (Type_ret[0] == 2'b11)? ((Type_ret[1] == 2'b11)? ((Type_ret[2] == 2'b11)? 3 : 2) :
                                                                             ((Type_ret[2] == 2'b11)? 2 : 1)):
                                                    ((Type_ret[1] == 2'b11)? ((Type_ret[2] == 2'b11)? 2 : 1) :
                                                                             ((Type_ret[2] == 2'b11)? 1 : 0));   
                    end
            default:count = 0;
        endcase
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 256; i = i + 1) begin
                mem_data[i]     <=  '0;
            end

            valid_Result_ls     <=  '0;
            mode_ls             <=  '0;
            tag_ROB_Result_ls   <=  '0;
            Result_ls           <=  '0;
            Pw_Result_ls        <=  '0;

            for (i = 0; i < 16; i = i + 1) begin
                fifo[i]         <=  '0;
            end
            valid_fifo          <=  '0;
            ptr_old             <=  '0;
            ptr_young           <=  '0;
        end
        else begin
            if (flush) begin
                valid_Result_ls     <=  '0;
                mode_ls             <=  '0;
                tag_ROB_Result_ls   <=  '0;
                Result_ls           <=  '0;
                Pw_Result_ls        <=  '0;

                for (i = 0; i < 16; i = i + 1) begin
                    fifo[i]         <=  '0;
                end
                valid_fifo          <=  '0;
                ptr_old             <=  '0;
                ptr_young           <=  '0;
            end
            else begin
                if (freeze_back) begin
                    valid_Result_ls     <=  valid_Result_ls;
                    mode_ls             <=  mode_ls;
                    tag_ROB_Result_ls   <=  tag_ROB_Result_ls;
                    Result_ls           <=  Result_ls;
                    Pw_Result_ls        <=  Pw_Result_ls;
                end
                else begin

                    // load 查询 FIFO 与 MEM
                    valid_Result_ls     <=  valid_ls;
                    mode_ls             <=  mode;
                    tag_ROB_Result_ls   <=  tag_ROB_ls;
                    Result_ls           <=  find_in_fifo? fifo_data : mem_data[Addr];
                    Pw_Result_ls        <=  Px;

                    // save 写入 FIFO
                    if (valid_ls && mode == 0) begin
                        fifo[ptr_young]         <=  {busX, Addr};
                        valid_fifo[ptr_young]   <=  1;
                        ptr_young               <=  ptr_young + 1;
                    end
                end

                // ROB 退休从 FIFO 写入 MEM
                case (count)
                    1:  begin
                        mem_data[fifo[ptr_old_wire[0]].Addr]    <=  fifo[ptr_old_wire[0]].data;
                        fifo[ptr_old_wire[0]]                   <=  '0;
                        valid_fifo[ptr_old_wire[0]]             <=  '0;
                        ptr_old                                 <=  ptr_old + 1;
                        end
                    2:  begin
                        mem_data[fifo[ptr_old_wire[0]].Addr]    <=  fifo[ptr_old_wire[0]].data;
                        fifo[ptr_old_wire[0]]                   <=  '0;
                        valid_fifo[ptr_old_wire[0]]             <=  '0;

                        mem_data[fifo[ptr_old_wire[1]].Addr]    <=  fifo[ptr_old_wire[1]].data;
                        fifo[ptr_old_wire[1]]                   <=  '0;
                        valid_fifo[ptr_old_wire[1]]             <=  '0;
                        ptr_old                                 <=  ptr_old + 2;
                        end
                    3:  begin
                        mem_data[fifo[ptr_old_wire[0]].Addr]    <=  fifo[ptr_old_wire[0]].data;
                        fifo[ptr_old_wire[0]]                   <=  '0;
                        valid_fifo[ptr_old_wire[0]]             <=  '0;

                        mem_data[fifo[ptr_old_wire[1]].Addr]    <=  fifo[ptr_old_wire[1]].data;
                        fifo[ptr_old_wire[1]]                   <=  '0;
                        valid_fifo[ptr_old_wire[1]]             <=  '0;

                        mem_data[fifo[ptr_old_wire[2]].Addr]    <=  fifo[ptr_old_wire[2]].data;
                        fifo[ptr_old_wire[2]]                   <=  '0;
                        valid_fifo[ptr_old_wire[2]]             <=  '0;
                        ptr_old                                 <=  ptr_old + 3;
                        end
                    default:                    ptr_old <=  ptr_old;
                endcase
            end
        end
    end


endmodule