`timescale 1ns / 1ps

//现在只有load的功能，尚未实现store，因为这需要调整广播总线
module LSQ (
    input               clk,
    input               rst,
    input               flush,
    input               freeze_front,
    input               freeze_back,
    input               valid_pc,
    output              full_LSQ,
    // x,y,z 端口写入
    input   [ 1 : 0]    Type        [2 : 0],
    input   [ 4 : 0]    Pa          [2 : 0], // Store的数据源寄存器 (Ra)
    input   [ 4 : 0]    Pb          [2 : 0], // Store/Load的基地址寄存器 (Rb)
    input               valid_Pa    [2 : 0],
    input               valid_Pb    [2 : 0], // 在你的设计中，AGU会处理地址，所以valid_Pb可能不直接用
    input   [ 4 : 0]    Pw          [2 : 0], // Load的目的寄存器
    input   [ 4 : 0]    tag_ROB     [2 : 0],
    
    // 唤醒 (这些信号现在表示可以向存储系统发射)
    output              valid_op_awake,
    output              mode_awake,
    output  [ 4 : 0]    Px_awake,
    output  [15 : 0]    Addr_awake,
    output  [ 4 : 0]    tag_ROB_awake,

    // 来自 FU 的广播, 唤醒 Px (Store的数据源)
    input   [ 4 : 0]    Pw_Result_add,
    input               valid_Result_add,
    input   [ 4 : 0]    Pw_Result_mul,
    input               valid_Result_mul,
    // input   [ 4 : 0]    Pw_Result_ls,    // 不再需要，因为LSQ自己产生
    // input               valid_Result_ls,
    // input               mode_ls,

    // LSQ 产生的Load结果广播
    output reg          valid_Result_ls_out,
    output reg [4:0]    Pw_Result_ls_out,
    output reg          mode_ls_out,

    // 来自 AGU 的广播, 唤醒 Addr
    input               valid_Addr_agu,
    input   [ 4 : 0]    tag_ROB_Result_agu,
    input   [15 : 0]    Addr_agu,

    // D-Cache 接口
    output reg          dc_read_req,
    output reg          dc_write_req,
    output reg [29:0]   dc_addr,
    output reg [3:0]    dc_byte_w_en,
    output reg [31:0]   dc_wdata,
    input  wire [31:0]  dc_rdata
);

    // LSQ 条目结构体
    typedef struct packed {
        reg     [ 4 : 0]    Px;      // Store: 数据源物理寄存器(Pa); Load: 目的物理寄存器(Pw)
        reg     [31 : 0]    Data;    // Store: 待写入的数据值
        reg     [15 : 0]    Addr;    // 访存地址
        reg     [ 4 : 0]    tag_ROB;
    } lsq_list;

    // LSQ 内部状态
    reg     [ 7 : 0]    valid_op_list;
    reg     [ 7 : 0]    mode_list;      // 1: Load, 0: Store
    reg     [ 7 : 0]    valid_Px_list;  // Px(数据源或目的地)是否就绪
    reg     [ 7 : 0]    valid_Addr_list;// Addr(地址)是否就绪
    lsq_list            list[7 : 0];
    
    // Load 指令状态跟踪
    reg                 load_req_sent;    // 标志：已向 D-Cache 发出读请求
    reg [4:0]           load_pending_pw;  // 正在等待数据的 Load 指令的目的寄存器 Pw

    // 指针和发射逻辑
    reg     [ 2 : 0]    ptr_old;
    reg     [ 2 : 0]    ptr_young;
    wire    [ 2 : 0]    ptr_young_wire[2 : 0];
    reg     [ 2 : 0]    ptr_awake;
    reg                 awake_exist;

    // token_list 用于实现 store-load 依赖和乱序发射控制
    reg     [ 7 : 0]    token_list;
    reg     [ 7 : 0]    shift_list;
    reg     [ 7 : 0]    token_temp;
    reg     [ 7 : 0]    shift_temp;

    integer i, j, k;
    genvar  gvi;

    // --- 逻辑实现 ---

    generate
        for (gvi = 0; gvi < 3; gvi = gvi + 1) begin
            assign ptr_young_wire[gvi] = ptr_young + gvi;
        end
    endgenerate

    assign full_LSQ = (valid_op_list[ptr_old] == 1 && (ptr_young_wire[0] == ptr_old || ptr_young_wire[1] == ptr_old || ptr_young_wire[2] == ptr_old));

    // --- 主要时序逻辑 ---
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            valid_op_list   <= '0;
            mode_list       <= '0;
            valid_Px_list   <= '0;
            valid_Addr_list <= '0;
            for (i = 0; i < 8; i = i + 1) list[i] <= '0;
            ptr_old         <= '0;
            ptr_young       <= '0;
            load_req_sent   <= 1'b0;
            load_pending_pw <= 5'b0;
        end
        else if (flush) begin
            valid_op_list   <= '0;
            mode_list       <= '0;
            valid_Px_list   <= '0;
            valid_Addr_list <= '0;
            for (i = 0; i < 8; i = i + 1) list[i] <= '0;
            ptr_old         <= '0;
            ptr_young       <= '0;
            load_req_sent   <= 1'b0;
            load_pending_pw <= 5'b0;
        end
        else begin
            // 1. 新指令进入 LSQ
            if (valid_pc && !freeze_front) begin
                for (i = 0; i < 3; i = i + 1) begin
                    if (Type[i] == 2'b10 || Type[i] == 2'b11) begin // Is it a Load/Store?
                        valid_op_list[ptr_young_wire[i]]    <= 1'b1;
                        mode_list[ptr_young_wire[i]]        <= Type[i][0]; // 1 for Load, 0 for Store //注意这里去掉一个取反
                        list[ptr_young_wire[i]].tag_ROB     <= tag_ROB[i];
                        valid_Addr_list[ptr_young_wire[i]]  <= 0; // 地址初始无效

                        if (Type[i][0] == 1'b0) begin // Store (Type is ...0)
                             list[ptr_young_wire[i]].Px       <= Pa[i];
                            valid_Px_list[ptr_young_wire[i]] <= valid_Pa[i];
                        end else begin // Load (Type is ...1)
                            list[ptr_young_wire[i]].Px       <= Pw[i];
                            valid_Px_list[ptr_young_wire[i]] <= 1'b1;
                        end
                    end
                end
                // ... ptr_young 更新逻辑 ...
                if (Type[2] == 2'b10 || Type[2] == 2'b11) begin
                        ptr_young   <=  ptr_young + 3;
                    end
                    else if (Type[1] == 2'b10 || Type[1] == 2'b11) begin
                        ptr_young   <=  ptr_young + 2;
                    end
                    else if (Type[0] == 2'b10 || Type[0] == 2'b11) begin
                        ptr_young   <=  ptr_young + 1;
                    end
                    else begin
                        ptr_young   <=  ptr_young;
                    end
            end

// 2. 将已成功发出请求的条目从 LSQ 中清除
//    使用最终的请求信号 dc_read_req 或 dc_write_req 作为确认，以避免竞争
if ( (dc_read_req || dc_write_req) && !freeze_back ) begin
    valid_op_list[ptr_awake] <= 1'b0;
    
    // 提醒：这里的 ptr_old 更新逻辑在乱序场景下仍然是有问题的，
    // 但它不影响当前这个 bug 的修复。正确的做法是与ROB commit同步。
    if (ptr_awake == ptr_old) begin
        ptr_old <= ptr_old + 1;
    end
end
            
            // 3. 跟踪已发出的 Load 请求
            if (dc_read_req) begin // 如果本周期发出了读请求
                load_req_sent   <= 1'b1;
                load_pending_pw <= list[ptr_awake].Px; // 记录这条Load指令的目的寄存器
            end else if (valid_Result_ls_out) begin // 如果上一个Load已完成
                load_req_sent <= 1'b0; // 清除标志
            end

            // 4. 接收广播，唤醒等待的操作数和地址
            // 唤醒 Store 的数据源 (Px)
            // **注意**: 这里的实现简化了数据捕获，它只标记数据就绪，但没存储数据值。
            // 一个完整的实现需要从CDB总线上捕获数据值并存入 list[i].Data。
            if (valid_Result_add) begin
                for (i = 0; i < 8; i = i + 1) if (valid_op_list[i] && !valid_Px_list[i] && list[i].Px == Pw_Result_add) valid_Px_list[i] <= 1'b1;
            end
            if (valid_Result_mul) begin
                for (i = 0; i < 8; i = i + 1) if (valid_op_list[i] && !valid_Px_list[i] && list[i].Px == Pw_Result_mul) valid_Px_list[i] <= 1'b1;
            end
            // 唤醒地址 (Addr)
            if (valid_Addr_agu) begin
                for (i = 0; i < 8; i = i + 1) begin
                    if (valid_op_list[i] && !valid_Addr_list[i] && list[i].tag_ROB == tag_ROB_Result_agu) begin
                        valid_Addr_list[i] <= 1'b1;
                        list[i].Addr       <= Addr_agu;
                    end
                end
            end
        end
    end

    // --- 组合逻辑 ---
    // 挑选一条可以发射的指令 (ptr_awake, awake_exist)
        always @(*) begin
        shift_temp  =   mode_list & valid_op_list;
        for (i = 0; i < 8; i = i + 1) begin
            j   =   (i + ptr_old >= 8)? i + ptr_old - 8 : i + ptr_old;
            shift_list[i]   =   shift_temp[j];
            k   =   (i + 8 - ptr_old >= 8)? i - ptr_old : i + 8 - ptr_old;
            token_list[i]   =   token_temp[k];
        end

        casez (shift_list)
            8'b????_???0:   token_temp  =   8'b0000_0001;
            8'b????_??01:   token_temp  =   8'b0000_0001;
            8'b????_?011:   token_temp  =   8'b0000_0011;
            8'b????_0111:   token_temp  =   8'b0000_0111;
            8'b???0_1111:   token_temp  =   8'b0000_1111;
            8'b??01_1111:   token_temp  =   8'b0001_1111;
            8'b?011_1111:   token_temp  =   8'b0011_1111;
            8'b0111_1111:   token_temp  =   8'b0111_1111;
            8'b1111_1111:   token_temp  =   8'b1111_1111;
            default:        token_temp  =   8'b0000_0000;
        endcase
    end

        always @(*) begin
        casez (valid_op_list & valid_Px_list & valid_Addr_list /*& token_list*/)
            8'b????_???1:   {ptr_awake, awake_exist}    =   {3'd0, 1'b1};
            8'b????_??10:   {ptr_awake, awake_exist}    =   {3'd1, 1'b1};
            8'b????_?100:   {ptr_awake, awake_exist}    =   {3'd2, 1'b1};
            8'b????_1000:   {ptr_awake, awake_exist}    =   {3'd3, 1'b1};
            8'b???1_0000:   {ptr_awake, awake_exist}    =   {3'd4, 1'b1};
            8'b??10_0000:   {ptr_awake, awake_exist}    =   {3'd5, 1'b1};
            8'b?100_0000:   {ptr_awake, awake_exist}    =   {3'd6, 1'b1};
            8'b1000_0000:   {ptr_awake, awake_exist}    =   {3'd7, 1'b1};
            default:        {ptr_awake, awake_exist}    =   {3'd0, 1'b0};
        endcase
    end



    // 根据挑出的指令，生成D-Cache请求
    always @(*) begin
        dc_read_req  = 1'b0;
        dc_write_req = 1'b0;
        dc_addr      = 30'b0;
        dc_byte_w_en = 4'b0;
        dc_wdata     = 32'b0;
        
        if (awake_exist && !freeze_back) begin
            if (mode_list[ptr_awake] == 1'b1) begin // Load 操作
                // 只有在没有其他Load正在等待时，才发出新的Load请求
                if (!load_req_sent) begin
                    dc_read_req = 1'b1;
                    dc_addr     = {14'b0, list[ptr_awake].Addr};
                end
            end else begin // Store 操作
                dc_write_req = 1'b1;
                dc_addr      = {14'b0, list[ptr_awake].Addr};
                // **关键**: 假设数据值已经被捕获到 list[ptr_awake].Data 中
                dc_wdata     = list[ptr_awake].Data;
                dc_byte_w_en = 4'b1111; // 假设写整个字
            end
        end
    end
    
    // 生成 LSQ 的 Load 结果广播
    // 当一个Load请求已发出，并且D-Cache返回了数据时
    // 假设D-Cache的响应是组合逻辑（为了简化，实际可能需要更复杂握手机制）
    // 你的cache_manage_unit的stall逻辑保证了此时dc_rdata是有效的
    always @(*) begin
        valid_Result_ls_out = 1'b0;
        Pw_Result_ls_out    = 5'b0;
        mode_ls_out         = 1'b0;
        if (load_req_sent && !dc_read_req) begin // 上周期发了请求，本周期没发（数据回来了）
             valid_Result_ls_out = 1'b1;
             Pw_Result_ls_out    = load_pending_pw;
             mode_ls_out         = 1'b1; // 1代表是Load结果
             // 还需要将 dc_rdata 广播出去，这需要修改广播总线
        end
    end

    // LSQ发射给存储系统的信号
    assign valid_op_awake = awake_exist && !freeze_back;
    assign mode_awake     = awake_exist ? mode_list[ptr_awake] : 1'b0;
    assign Px_awake       = awake_exist ? list[ptr_awake].Px : 5'b0;
    assign Addr_awake     = awake_exist ? list[ptr_awake].Addr : 16'b0;
    assign tag_ROB_awake  = awake_exist ? list[ptr_awake].tag_ROB : 5'b0;

endmodule