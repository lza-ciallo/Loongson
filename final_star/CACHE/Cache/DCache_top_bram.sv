module DCache_top #(
    parameter WAYS = 2,
    parameter CACHELINE_WIDTH = 128,
    parameter CACHELINE_NUMS = 1024,
    parameter PC_WIDTH = 10,
    parameter TAG_WIDTH = 18
)(
    // 系统信号
    input          clk,
    input          rst,
    // 面向控制单元的信号
    input          flush_DCache,
    output         stall_mem_request,
    // 面向访存模块的数据传输线
    input [31:0]   addr,
    input [3:0]    Conf_dmem,//配置信息，只需要识别B/H/W即可,结合addr的最后两位判断
    input [31:0]   Wdata,
    input          Wena,
    output         Wdone,
    output [31:0]  Rdata,
    input          Rena,
    output         Rdone,
    // 面向axi总线DCache读写的相应信号
    output         req_valid,
    input          req_ready,
    output [31:0]  req_addr,
    output         write_en,
    output [127:0] req_Wdata,
    input          res_valid,
    output         res_ready,
    input  [127:0] res_Rdata,
    input  [1:0]   axi_Wdone,
    // 面向axi总线Data for confreg读写的相关信号
    // 数据请求接口 (原 dataReq) for confreg
    output  [31:0]  data_addr,
    output  [31:0]  data_wdata,
    output          data_write_en,
    output  [3:0]   data_strobe,
    output  [2:0]   data_size,
    output          data_req_valid,
    input           data_req_ready,
    
    // 数据响应接口 (原 dataResp) for confreg
    input [31:0]   data_rdata,
    input          data_resp_valid,
    output         data_resp_ready
);

    // 处理mask/size/conf/addr的转化问题
    reg [3:0]  Wmask;
    reg [2:0]  Wsize;
    // reg [3:0]  Rmask;
    always_comb begin
        if(Conf_dmem == 0 || Conf_dmem == 3 || Conf_dmem == 6)begin//B
            case (addr[1:0])
                2'b00: Wmask = 4'b0001;
                2'b01: Wmask = 4'b0010;
                2'b10: Wmask = 4'b0100;
                2'b11: Wmask = 4'b1000;
            endcase
            Wsize = 2'b00;
        end
        else if(Conf_dmem == 1 || Conf_dmem == 4 || Conf_dmem == 7)begin//H
            case (addr[1:0])
                2'b00: Wmask = 4'b0011;
                2'b01: Wmask = 4'b0011;
                2'b10: Wmask = 4'b1100;
                2'b11: Wmask = 4'b1100;
            endcase
            Wsize = 2'b01;
        end
        else if(Conf_dmem == 2 || Conf_dmem == 5)begin//W
            Wmask = 4'b1111;
            Wsize = 2'b10;
        end
        else begin
            Wmask = 4'b0000; // 默认值，防止综合错误
            Wsize = 2'b11;
        end
    end
    wire [31:0] Waddr;
    wire [31:0] Raddr;
    assign      Waddr = addr;
    assign      Raddr = addr;

    reg  [31:0]     Wdata_mydick;
    always_comb begin
        Wdata_mydick = Wdata;
        case(Wsize)
            2'b00:begin
                case(addr[1:0])
                    2'b00:Wdata_mydick[7:0]   = Wdata[7:0];
                    2'b01:Wdata_mydick[15:8]  = Wdata[7:0];
                    2'b10:Wdata_mydick[23:16] = Wdata[7:0];
                    2'b11:Wdata_mydick[31:24] = Wdata[7:0];
                endcase
            end
            2'b01:begin
                case(addr[1:0])
                    2'b00:Wdata_mydick[15:0]   = Wdata[15:0];
                    2'b10:Wdata_mydick[31:16] = Wdata[15:0];
                endcase
            end
        endcase
    end
    // ===================================================================
    // 新增：特定地址判断逻辑
    // ===================================================================
    wire is_data_addr;
    // 根据data_addr.txt中的地址范围设置判断逻辑
    assign is_data_addr = (addr[31:16] == 16'hbfaf) ||  // 0xBFAFxxxx
                         (addr[31:16] == 16'hbfd0) ||  // 0xBFD0xxxx
                         (addr[31:16] == 16'h1fd0) ||    // 0x1FD0xxxx
                         (addr[31:16] == 16'hbfe0);
    
    // ===================================================================
    // 新增：Data旁路状态机
    // ===================================================================
    typedef enum { 
        data_idle,
        data_req,
        data_resp
    } DataState;
    
    DataState data_current_state, data_next_state;
    
    typedef enum { 
        fastresponse, 
        reqprocess,        // 新增状态：处理读写请求
        waithandshaking_clean,
        waithandshaking_dirty_addr,
        waithandshaking_dirty_data,
        waitresponse 
    } DCache_state;
    
    // 状态寄存器
    DCache_state current_state, next_state;

    // 新增：Data请求锁存寄存器
    reg [31:0] saved_addr_data;
    reg [31:0] saved_data_data;
    reg        saved_we_data;
    reg [3:0]  saved_mask_data;
    reg [2:0]  saved_wsize;
    reg        saved_is_data_addr; 
    
    // 状态寄存器更新
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            data_current_state <= data_idle;
        end else begin
            data_current_state <= data_next_state;
        end
    end
    
    // Data状态机转移逻辑
    always_comb begin
        data_next_state = data_current_state;
        unique case (data_current_state)
            data_idle: begin
                if ((Rena || Wena) && is_data_addr) begin
                    data_next_state = data_req;
                end
            end
            data_req: begin
                if (data_req_ready) begin
                    data_next_state = data_resp;
                end
            end
            data_resp: begin
                if (data_resp_valid || saved_we_data) begin
                    data_next_state = data_idle;
                end
            end
        endcase
    end
    
    // Data请求锁存逻辑
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            saved_addr_data  <= 32'b0;
            saved_data_data  <= 32'b0;
            saved_we_data    <= 1'b0;
            saved_mask_data  <= 4'b0;
            
        end else if (data_current_state == data_idle && 
                   (Rena || Wena) && is_data_addr) begin
            saved_addr_data  <= addr;
            saved_data_data  <= Wdata_mydick;
            saved_we_data    <= Wena;
            saved_mask_data  <= Wmask;
        end
    end
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            saved_is_data_addr <= 1'b0;
            saved_wsize      <= 2'b0;
        end else if (data_current_state == data_idle && current_state == fastresponse &&
                   (Rena || Wena)) begin
            saved_is_data_addr <= is_data_addr;
            saved_wsize        <= Wsize;
        end
    end
    
    // Data接口输出逻辑
    assign data_addr        = saved_addr_data;
    assign data_wdata       = saved_data_data;
    assign data_write_en    = saved_we_data;
    assign data_strobe      = saved_mask_data;
    assign data_size        = saved_wsize; // 固定为字传输
    assign data_req_valid   = (data_current_state == data_req);
    assign data_resp_ready  = (data_current_state == data_resp);
    
    // ===================================================================
    // 原有DCache状态机（增加对is_data_addr的防护）
    // ===================================================================
    
    
    // DCache_unit接口信号
    wire hit;
    wire replace_way;
    wire [31:0] replace_addr; // 新增：被替换块的实际地址
    wire dirty;
    wire [127:0] wb_DCache_line;
    
    // 锁存请求信息（增加is_data_addr防护）
    reg [31:0] saved_addr;
    reg [31:0] saved_data;
    reg [3:0]  saved_mask;
    reg        saved_we;
    reg        saved_replace_way;
    reg [31:0] saved_replace_addr;
    
    // 状态寄存器更新
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= fastresponse;
        end else begin
            current_state <= next_state;
        end
    end
    
    // 状态转移逻辑（增加is_data_addr防护）
    always_comb begin
        next_state = current_state;
        unique case (current_state)
            fastresponse: begin
                // 读写请求（排除Data地址）
                if ((Rena || Wena) && !is_data_addr) begin
                    if (hit) begin
                        next_state = reqprocess;
                    end else begin
                        // 未命中根据dirty位决定状态转移
                        if (dirty) begin
                            next_state = waithandshaking_dirty_addr;
                        end else begin
                            next_state = waithandshaking_clean;
                        end
                    end
                end
            end
            reqprocess: begin
                next_state = fastresponse;
            end
            waithandshaking_dirty_addr: begin
                if (req_ready) begin
                    next_state = waithandshaking_dirty_data;
                end
            end
            waithandshaking_dirty_data: begin
                next_state = waithandshaking_clean;
            end
            waithandshaking_clean: begin
                if (req_ready) begin
                    next_state = waitresponse;
                end
            end
            waitresponse: begin
                if (res_valid) begin
                    next_state = fastresponse;
                end
            end
        endcase
    end
    
    // 锁存请求信息（增加is_data_addr防护）
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            saved_addr <= 32'b0;
            saved_data <= 32'b0;
            saved_mask <= 4'b0;
            saved_we <= 1'b0;
            saved_replace_way <= 1'b0;
            saved_replace_addr <= 32'b0;
        end else begin
            // 在fastresponse状态锁存请求信息（排除Data地址）
            if (current_state == fastresponse && (Rena || Wena) && !is_data_addr) begin
                saved_addr <= Wena ? Waddr : Raddr;
                saved_data <= Wdata;
                saved_mask <= Wmask;
                saved_we <= Wena;
                saved_replace_way <= replace_way;
                saved_replace_addr <= replace_addr; // 锁存被替换块的实际地址
            end
        end
    end
    
    // ===================================================================
    // 输出逻辑整合（合并两个状态机的输出）
    // ===================================================================
    
    // 旁路处理中的信号
    wire data_processing = (data_current_state != data_idle);
    
    // 流控信号
    reg stall_data_reg, stall_DCache_reg;
    always_comb begin 
        // 默认值
        stall_data_reg = 1;
        stall_DCache_reg = 1;
        
        // Data状态机流控
        if(data_current_state == data_resp)begin
            stall_data_reg = ~data_resp_valid && ~saved_we_data;
        end else begin
            stall_data_reg = 1;
        end
        
        // // DCache状态机流控
        // if(current_state == waitresponse)begin
        //     stall_DCache_reg = ~res_valid;
        // end else begin
        //     stall_DCache_reg = 1;
        // end
    end 
    // wire stall_mem_request0 = (current_state != fastresponse && current_state != reqprocess) || 
    //                            data_processing || 
    //                           ((current_state == fastresponse || data_current_state == data_idle) && (Rena || Wena));
    wire stall_mem_request0 = (current_state != fastresponse && current_state != reqprocess) || 
                                data_processing || 
                                ((current_state == fastresponse || (~hit &&(data_current_state == data_idle))) && (Rena || Wena));
    assign stall_mem_request = stall_data_reg && stall_DCache_reg && stall_mem_request0;
    
    // DCache接口信号
    assign req_valid = (current_state == waithandshaking_dirty_addr) || (current_state == waithandshaking_dirty_data) || (current_state == waithandshaking_clean);
    
    assign write_en = (current_state == waithandshaking_dirty_addr) ;
    // || (current_state == waithandshaking_dirty_data);
    
    assign req_addr = (current_state == waithandshaking_dirty_addr) ? 
                     {saved_replace_addr[31:4], 4'b0} :  // 写回地址对齐
                     {saved_addr[31:4], 4'b0};    // 读请求地址对齐
    
    assign req_Wdata = wb_DCache_line;
    
    assign res_ready = (current_state == waitresponse);
    
    // 完成信号整合
    wire cache_rdone = (current_state == reqprocess) && !saved_we;
    wire cache_wdone = (current_state == reqprocess) && saved_we;
    
    wire data_rdone = (data_current_state == data_resp) && 
                     data_resp_valid && !saved_we_data;
    wire data_wdone = (data_current_state == data_resp) && 
                     data_resp_valid && saved_we_data;
    
    assign Rdone = cache_rdone || data_rdone;
    assign Wdone = cache_wdone || data_wdone;
    
    // ===================================================================
    // DCache更新控制（增加is_data_addr防护）
    // ===================================================================
    reg DCache_Wena;
    reg [31:0] update_addr_reg;
    reg update_way_reg;
    
    always_comb begin
        DCache_Wena = 1'b0;
        update_addr_reg = 32'b0;
        update_way_reg = 1'b0;
        
        // 确保不会更新Data地址的Cache
        if (current_state == waitresponse && res_valid && !saved_is_data_addr) begin
            DCache_Wena = 1'b1;
            update_addr_reg = saved_addr;
            update_way_reg = saved_replace_way;
        end
    end
    
    // 写回控制（增加is_data_addr防护）
    reg wb_ena;
    reg [31:0] wb_addr_reg;
    reg wb_way_reg;
    
    always_comb begin
        wb_ena = 1'b0;
        wb_addr_reg = 32'b0;
        wb_way_reg = saved_replace_way;
        
        // 确保不会写回Data地址
        if (current_state == waithandshaking_dirty_addr && req_ready && !saved_is_data_addr) begin
            wb_ena = 1'b1;
            wb_addr_reg = saved_replace_addr;
            wb_way_reg = saved_replace_way;
        end
    end
    
    // ===================================================================
    // 数据输出选择器
    // ===================================================================
    wire [31:0] Rdata_from_dcache;
    
    // 优先选择旁路数据，然后是Cache数据
    reg data_rdone_fuck;
    always_ff @( posedge clk or negedge rst) begin 
        if(!rst)begin
            data_rdone_fuck <= 0;
        end
        else begin
            if(data_current_state == data_resp)begin
                data_rdone_fuck <= data_rdone;
            end
            else begin
                data_rdone_fuck <= 0;
            end
        end
    end
    assign Rdata = (data_rdone || data_rdone_fuck)? data_rdata : Rdata_from_dcache;
    
    // ===================================================================
    // DCache单元实例化（增加对is_data_addr的防护）
    // ===================================================================
    DCache_unit dcache_unit (
        .clk(clk),
        .rst(rst),
        // 防护：Data地址请求不进入Cache
        .data_read_ena(Rena && (current_state == fastresponse) && !is_data_addr),
        .data_write_ena(Wena && (current_state == fastresponse) && !is_data_addr),
        .addr(Wena ? Waddr : Raddr),
        .hit(hit),
        .data_read(Rdata_from_dcache),
        .Wmask(Wmask),
        .data_write(Wdata),
        .replace_way(replace_way),
        .replace_addr(replace_addr), // 新增：被替换块的实际地址
        .dirty(dirty),
        .DCache_Wena(DCache_Wena),
        .update_way(update_way_reg),
        .update_addr(update_addr_reg),
        .update_DCache_line(res_Rdata),
        .wb_ena(wb_ena),
        .wb_addr(wb_addr_reg),
        .wb_way(wb_way_reg),
        .wb_DCache_line(wb_DCache_line),
        // 新增信号
        .process_ena(current_state == reqprocess && !saved_is_data_addr),
        .saved_we(saved_we),
        .saved_addr(saved_addr),
        .saved_data(saved_data),
        .saved_mask(saved_mask),
        .saved_size(saved_wsize)
    );
endmodule