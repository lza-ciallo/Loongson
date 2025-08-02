`include "../defs.svh"

module LSUQ (
    input                   clk,
    input                   rst,
    input                   flush_lsuq,
    input                   stall_in,
    input                   stall_lsuq,
    output                  full_lsuq,

    input                   ready_pc        [2 : 0],
    input       [ 5 : 0]    Pd_old          [2 : 0],
    input                   valid_Pd_old    [2 : 0],
    input       [ 5 : 0]    Pd              [2 : 0],
    input       [ 2 : 0]    Type            [2 : 0],
    input       [ 3 : 0]    Conf            [2 : 0],
    input                   RegWr           [2 : 0],
    input                   has_excp        [2 : 0],

    output  reg             ready_awake,
    output  reg [ 5 : 0]    Px_awake,
    output  reg [31 : 0]    Addr_awake,
    output  reg [ 3 : 0]    Conf_awake,
    output  reg             RegWr_awake,
    output  reg [ 5 : 0]    tag_rob_awake,
    output  reg             has_excp_awake,

    // from ROB
    input       [ 5 : 0]    tag_rob     [2 : 0],

    // from AGU
    input                   ready_agu,
    input       [ 5 : 0]    tag_rob_agu,
    input       [31 : 0]    Addr_agu,

    // from CDB
    input                   ready_cdb   [4 : 0],
    input                   RegWr_cdb   [4 : 0],
    input       [ 5 : 0]    Pd_cdb      [4 : 0]
);

    typedef struct packed {
        reg     [ 5 : 0]    Px;
        reg     [31 : 0]    Addr;
        reg     [ 3 : 0]    Conf;
        reg     [ 5 : 0]    tag_rob;
        reg                 has_excp;
    } lsuq_entry;

    lsuq_entry          lsuq_list   [15 : 0];

    reg     [15 : 0]    ready_list;
    reg     [15 : 0]    ready_Px_list;
    reg     [15 : 0]    ready_Addr_list;
    reg     [15 : 0]    RegWr_list;

    reg     [ 3 : 0]    ptr_old;
    reg     [ 3 : 0]    ptr_young;

    wire    [ 3 : 0]    ptr_write   [2 : 0];
    assign  ptr_write[0]    =   ptr_young;
    assign  ptr_write[1]    =   ptr_young + 1;
    assign  ptr_write[2]    =   ptr_young + 2;

    assign  full_lsuq       =   ((ptr_write[0] == ptr_old || ptr_write[1] == ptr_old || ptr_write[2] == ptr_old) &&
                                (ready_list[ptr_old] == 1))? 1 : 0;

    reg     [ 3 : 0]    ptr_awake;
    reg                 awake_exist;

    // 写入时被迫采用密堆积
    reg     [ 2 : 0]    write_temp;
    integer write_index [2 : 0];
    integer write_num;
    always @(*) begin
        for (integer i = 0; i < 3; i = i + 1) begin
            write_temp[i] = (Type[i] == `LSU_TYPE && ready_pc[i])? 1 : 0;
        end
        case (write_temp)
            3'b000: begin   write_index[0] = 3; write_index[1] = 3; write_index[2] = 3; write_num = 0; end
            3'b001: begin   write_index[0] = 0; write_index[1] = 3; write_index[2] = 3; write_num = 1; end
            3'b010: begin   write_index[0] = 3; write_index[1] = 0; write_index[2] = 3; write_num = 1; end
            3'b011: begin   write_index[0] = 0; write_index[1] = 1; write_index[2] = 3; write_num = 2; end
            3'b100: begin   write_index[0] = 3; write_index[1] = 3; write_index[2] = 0; write_num = 1; end
            3'b101: begin   write_index[0] = 0; write_index[1] = 3; write_index[2] = 1; write_num = 2; end
            3'b110: begin   write_index[0] = 3; write_index[1] = 0; write_index[2] = 1; write_num = 2; end
            3'b111: begin   write_index[0] = 0; write_index[1] = 1; write_index[2] = 2; write_num = 3; end
        endcase
    end

    // 发射时排除后面的气泡
    reg     [15 : 0]    ready_temp;
    integer temp_p;
    always @(*) begin
        for (integer i = 0; i < 16; i = i + 1) begin
            temp_p = (i + ptr_old >= 16)? i + ptr_old - 16 : i + ptr_old;
            ready_temp[i] = ready_list[temp_p];
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            ready_list                          <=  '0;
            ready_Px_list                       <=  '0;
            ready_Addr_list                     <=  '0;
            RegWr_list                          <=  '0;
            for (integer i = 0; i < 16; i = i + 1) begin
                lsuq_list[i]                    <=  '0;
            end
            ready_awake                         <=  '0;
            RegWr_awake                         <=  '0;
            {Px_awake, Addr_awake, Conf_awake, tag_rob_awake,
                has_excp_awake}                 <=  '0;
            ptr_old                             <=  '0;
            ptr_young                           <=  '0;
        end
        else begin
            if (flush_lsuq) begin
                ready_list                      <=  '0;
                ready_Px_list                   <=  '0;
                ready_Addr_list                 <=  '0;
                RegWr_list                      <=  '0;
                for (integer i = 0; i < 16; i = i + 1) begin
                    lsuq_list[i]                <=  '0;
                end
                ready_awake                     <=  '0;
                RegWr_awake                     <=  '0;
                {Px_awake, Addr_awake, Conf_awake, tag_rob_awake,
                    has_excp_awake}             <=  '0;
                ptr_old                         <=  '0;
                ptr_young                       <=  '0;
            end
            else begin
                
                // write in 3 uop's in order
                if (!full_lsuq && !stall_in) begin
                    for (integer i = 0; i < 3; i = i + 1) begin
                        if (write_index[i] != 3) begin
                            ready_list[ptr_write[write_index[i]]]       <=  1;
                            ready_Px_list[ptr_write[write_index[i]]]    <=  RegWr[i]? 1 :
                                                                            (Pd_old[i] == Pd_cdb[0] && ready_cdb[0] && RegWr_cdb[0]) ||
                                                                            (Pd_old[i] == Pd_cdb[1] && ready_cdb[1] && RegWr_cdb[1]) ||
                                                                            (Pd_old[i] == Pd_cdb[2] && ready_cdb[2] && RegWr_cdb[2]) ||
                                                                            (Pd_old[i] == Pd_cdb[3] && ready_cdb[3] && RegWr_cdb[3]) ||
                                                                            (Pd_old[i] == Pd_cdb[4] && ready_cdb[4] && RegWr_cdb[4])? 1 : valid_Pd_old[i];
                            ready_Addr_list[ptr_write[write_index[i]]]  <=  0;
                            RegWr_list[ptr_write[write_index[i]]]       <=  RegWr[i];
                            lsuq_list[ptr_write[write_index[i]]]        <=  RegWr[i]? {Pd[i], 32'b0, Conf[i], tag_rob[i], has_excp[i]} :
                                                                            {Pd_old[i], 32'b0, Conf[i], tag_rob[i], has_excp[i]};
                        end
                    end
                    // renew ptr_young
                    ptr_young   <=  ptr_young + write_num;
                end

                // awake 1 uop
                if (!stall_lsuq) begin
                    if (awake_exist) begin
                        ready_awake                     <=  ready_list[ptr_awake];
                        RegWr_awake                     <=  RegWr_list[ptr_awake];
                        {Px_awake, Addr_awake, Conf_awake, tag_rob_awake,
                            has_excp_awake}             <=  lsuq_list[ptr_awake];
                        ready_list[ptr_awake]           <=  '0;
                        RegWr_list[ptr_awake]           <=  '0;
                        ready_Px_list[ptr_awake]        <=  '0;
                        ready_Addr_list[ptr_awake]      <=  '0;
                        lsuq_list[ptr_awake]            <=  '0;
                        // 排除气泡
                        if (ptr_awake == ptr_old) begin
                            casez (ready_temp)
                                16'b????_????_????_??11:    ptr_old <=  ptr_old + 1;
                                16'b????_????_????_?101:    ptr_old <=  ptr_old + 2;
                                16'b????_????_????_1001:    ptr_old <=  ptr_old + 3;
                                16'b????_????_???1_0001:    ptr_old <=  ptr_old + 4;
                                16'b????_????_??10_0001:    ptr_old <=  ptr_old + 5;
                                16'b????_????_?100_0001:    ptr_old <=  ptr_old + 6;
                                16'b????_????_1000_0001:    ptr_old <=  ptr_old + 7;
                                16'b????_???1_0000_0001:    ptr_old <=  ptr_old + 8;
                                16'b????_??10_0000_0001:    ptr_old <=  ptr_old + 9;
                                16'b????_?100_0000_0001:    ptr_old <=  ptr_old + 10;
                                16'b????_1000_0000_0001:    ptr_old <=  ptr_old + 11;
                                16'b???1_0000_0000_0001:    ptr_old <=  ptr_old + 12;
                                16'b??10_0000_0000_0001:    ptr_old <=  ptr_old + 13;
                                16'b?100_0000_0000_0001:    ptr_old <=  ptr_old + 14;
                                16'b1000_0000_0000_0001:    ptr_old <=  ptr_old + 15;
                                default:                    ptr_old <=  ptr_old + 1;
                            endcase
                        end
                    end
                    else begin
                        ready_awake                     <=  '0;
                        RegWr_awake                     <=  '0;
                        {Px_awake, Addr_awake, Conf_awake, tag_rob_awake,
                            has_excp_awake}             <=  '0;
                    end
                end
                else begin
                    ready_awake                     <=  ready_awake;
                    RegWr_awake                     <=  RegWr_awake;
                    {Px_awake, Addr_awake, Conf_awake, tag_rob_awake, has_excp_awake}
                        <=  {Px_awake, Addr_awake, Conf_awake, tag_rob_awake, has_excp_awake};
                end

                // CDB
                for (integer i = 0; i < 5; i = i + 1) begin
                    if (ready_cdb[i] && RegWr_cdb[i]) begin
                        for (integer j = 0; j < 16; j = j + 1) begin
                            if (lsuq_list[j].Px == Pd_cdb[i] && ready_list[j] == 1) begin
                                ready_Px_list[j]    <=  1;
                            end
                        end
                    end
                end

                // AGU
                if (ready_agu) begin
                    for (integer i = 0; i < 16; i = i + 1) begin
                        if (lsuq_list[i].tag_rob == tag_rob_agu && ready_list[i] == 1) begin
                            ready_Addr_list[i]      <=  1;
                            lsuq_list[i].Addr       <=  Addr_agu;
                        end
                    end
                end
            end
        end
    end

    // generate ptr_awake & awake_exist
    reg     [15 : 0]    shift_list;
    reg     [15 : 0]    shift_temp;
    reg     [15 : 0]    token_list;
    reg     [15 : 0]    token_temp;

    integer temp_j;
    integer temp_k;

    always @(*) begin
        shift_temp = ready_list & RegWr_list;
        for (integer i = 0; i < 16; i = i + 1) begin
            temp_j = (i + ptr_old >= 16)? i + ptr_old - 16 : i + ptr_old;
            shift_list[i] = shift_temp[temp_j];
            temp_k = (i - ptr_old  + 16 >= 16)? i - ptr_old : i - ptr_old + 16;
            token_list[i] = token_temp[temp_k];
        end

        casez (shift_list)
            16'b????_????_????_???0:    token_temp  =   16'b0000_0000_0000_0001;
            16'b????_????_????_??01:    token_temp  =   16'b0000_0000_0000_0001;
            16'b????_????_????_?011:    token_temp  =   16'b0000_0000_0000_0011;
            16'b????_????_????_0111:    token_temp  =   16'b0000_0000_0000_0111;

            16'b????_????_???0_1111:    token_temp  =   16'b0000_0000_0000_1111;
            16'b????_????_??01_1111:    token_temp  =   16'b0000_0000_0001_1111;
            16'b????_????_?011_1111:    token_temp  =   16'b0000_0000_0011_1111;
            16'b????_????_0111_1111:    token_temp  =   16'b0000_0000_0111_1111;

            16'b????_???0_1111_1111:    token_temp  =   16'b0000_0000_1111_1111;
            16'b????_??01_1111_1111:    token_temp  =   16'b0000_0001_1111_1111;
            16'b????_?011_1111_1111:    token_temp  =   16'b0000_0011_1111_1111;
            16'b????_0111_1111_1111:    token_temp  =   16'b0000_0111_1111_1111;

            16'b???0_1111_1111_1111:    token_temp  =   16'b0000_1111_1111_1111;
            16'b??01_1111_1111_1111:    token_temp  =   16'b0001_1111_1111_1111;
            16'b?011_1111_1111_1111:    token_temp  =   16'b0011_1111_1111_1111;
            16'b0111_1111_1111_1111:    token_temp  =   16'b0111_1111_1111_1111;

            16'b1111_1111_1111_1111:    token_temp  =   16'b1111_1111_1111_1111;
            default:                    token_temp  =   16'b0000_0000_0000_0000;
        endcase

        casez (ready_list & ready_Px_list & ready_Addr_list & token_list)
            16'b????_????_????_???1:    {ptr_awake, awake_exist}    =   {4'd0, 1'b1};
            16'b????_????_????_??10:    {ptr_awake, awake_exist}    =   {4'd1, 1'b1};
            16'b????_????_????_?100:    {ptr_awake, awake_exist}    =   {4'd2, 1'b1};
            16'b????_????_????_1000:    {ptr_awake, awake_exist}    =   {4'd3, 1'b1};

            16'b????_????_???1_0000:    {ptr_awake, awake_exist}    =   {4'd4, 1'b1};
            16'b????_????_??10_0000:    {ptr_awake, awake_exist}    =   {4'd5, 1'b1};
            16'b????_????_?100_0000:    {ptr_awake, awake_exist}    =   {4'd6, 1'b1};
            16'b????_????_1000_0000:    {ptr_awake, awake_exist}    =   {4'd7, 1'b1};

            16'b????_???1_0000_0000:    {ptr_awake, awake_exist}    =   {4'd8, 1'b1};
            16'b????_??10_0000_0000:    {ptr_awake, awake_exist}    =   {4'd9, 1'b1};
            16'b????_?100_0000_0000:    {ptr_awake, awake_exist}    =   {4'd10, 1'b1};
            16'b????_1000_0000_0000:    {ptr_awake, awake_exist}    =   {4'd11, 1'b1};

            16'b???1_0000_0000_0000:    {ptr_awake, awake_exist}    =   {4'd12, 1'b1};
            16'b??10_0000_0000_0000:    {ptr_awake, awake_exist}    =   {4'd13, 1'b1};
            16'b?100_0000_0000_0000:    {ptr_awake, awake_exist}    =   {4'd14, 1'b1};
            16'b1000_0000_0000_0000:    {ptr_awake, awake_exist}    =   {4'd15, 1'b1};
            default:                    {ptr_awake, awake_exist}    =   {4'd0, 1'b0};
        endcase
    end

endmodule