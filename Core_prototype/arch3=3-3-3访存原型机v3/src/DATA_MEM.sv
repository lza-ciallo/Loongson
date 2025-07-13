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
    reg     [15 : 0]    fifo_match_list;    //  ptr_old->0 起始位置偏移
    reg     [ 3 : 0]    match_entry;        //  加偏移的最近匹配条目

    wire    [ 2 : 0]    ready_ret_wire;
    wire    [ 2 : 0]    excep_ret_wire;

    wire    [ 3 : 0]    ptr_old_wire    [  2 : 0];

    integer i, j, count;

    // full_FIFO 判定
    assign  full_FIFO   =   (valid_fifo == 16'hffff)? 1 : 0;

    // 在 FIFO 中尝试搜索对应条目
    always @(*) begin
        for (i = 0; i < 16; i = i + 1) begin
            j   =   (i + ptr_old >= 16)? i + ptr_old - 16 : i + ptr_old;
            //检查是否有条目的地址fifo[j].Addr与当前Load指令的地址Addr相匹配
            fifo_match_list[i]  =   (valid_fifo[j] == 1 && fifo[j].Addr == Addr)? 1 : 0;
        end

        //获取最新的、程序顺序上最接近的Store数据
        casez (fifo_match_list)
            16'b1???_????_????_????:    {match_entry, find_in_fifo}   =   {4'd15, 1'b1};
            16'b01??_????_????_????:    {match_entry, find_in_fifo}   =   {4'd14, 1'b1};
            16'b001?_????_????_????:    {match_entry, find_in_fifo}   =   {4'd13, 1'b1};
            16'b0001_????_????_????:    {match_entry, find_in_fifo}   =   {4'd12, 1'b1};
            16'b0000_1???_????_????:    {match_entry, find_in_fifo}   =   {4'd11, 1'b1};
            16'b0000_01??_????_????:    {match_entry, find_in_fifo}   =   {4'd10, 1'b1};
            16'b0000_001?_????_????:    {match_entry, find_in_fifo}   =   { 4'd9, 1'b1};
            16'b0000_0001_????_????:    {match_entry, find_in_fifo}   =   { 4'd8, 1'b1};

            16'b0000_0000_1???_????:    {match_entry, find_in_fifo}   =   { 4'd7, 1'b1};
            16'b0000_0000_01??_????:    {match_entry, find_in_fifo}   =   { 4'd6, 1'b1};
            16'b0000_0000_001?_????:    {match_entry, find_in_fifo}   =   { 4'd5, 1'b1};
            16'b0000_0000_0001_????:    {match_entry, find_in_fifo}   =   { 4'd4, 1'b1};
            16'b0000_0000_0000_1???:    {match_entry, find_in_fifo}   =   { 4'd3, 1'b1};
            16'b0000_0000_0000_01??:    {match_entry, find_in_fifo}   =   { 4'd2, 1'b1};
            16'b0000_0000_0000_001?:    {match_entry, find_in_fifo}   =   { 4'd1, 1'b1};
            16'b0000_0000_0000_0001:    {match_entry, find_in_fifo}   =   { 4'd0, 1'b1};
            default:                    {match_entry, find_in_fifo}   =   { 4'd0, 1'b0};
        endcase

        fifo_data   =   (match_entry + ptr_old >= 16)? fifo[match_entry + ptr_old - 16].data : fifo[match_entry + ptr_old].data;

        // fifo_data       =   0;
        // find_in_fifo    =   0;
        // find_stop       =   0;
        // for (j = 15; j >= 0; j = j - 1) begin
        //     k = (j + ptr_old >= 16)? j + ptr_old - 16 : j + ptr_old;
        //     if (find_stop == 0 && valid_fifo[k] == 1) begin
        //         if (fifo[k].Addr == Addr) begin
        //             fifo_data       =   fifo[k].data;
        //             find_in_fifo    =   1;
        //             find_stop       =   1;
        //         end
        //     end
        // end
    end

    // 退休的 save 计数
    assign  ptr_old_wire[0] =   ptr_old;
    assign  ptr_old_wire[1] =   ptr_old + 1;
    assign  ptr_old_wire[2] =   ptr_old + 2;

    assign  ready_ret_wire  =   {ready_ret[2], ready_ret[1], ready_ret[0]};
    assign  excep_ret_wire  =   {excep_ret[2], excep_ret[1], excep_ret[0]};
    //筛选store类型
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
                    Result_ls           <=  find_in_fifo? fifo_data : mem_data[Addr];//Store-to-Load Forwarding
                    Pw_Result_ls        <=  Px;

                    // save 写入 FIFO
                    if (valid_ls && mode == 0) begin
                        //将其数据和地址存入fifo的尾部，并移动尾指针
                        fifo[ptr_young]         <=  {busX, Addr};
                        valid_fifo[ptr_young]   <=  1;
                        ptr_young               <=  ptr_young + 1;
                    end
                end

                // ROB 退休从 FIFO 写入 MEM
                case (count)
                //根据之前计算出的count值，它从fifo的头部(取出1、2或3个最老的Store条目
                //将它们的数据写入mem_data，然后将这些条目从fifo中清空，并向前移动头指针ptr_old
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
