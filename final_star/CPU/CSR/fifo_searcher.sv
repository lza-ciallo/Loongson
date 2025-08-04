typedef struct packed {
    reg             csrWr;
    reg [13 : 0]    csrWr_addr;
    reg [31 : 0]    csrWr_data;
} csrfifo_entry;


module fifo_searcher (
    input   csrfifo_entry   csrfifo [15 : 0],
    input       [ 3 : 0]    ptr_old,
    input       [13 : 0]    rd_addr,
    output  reg             find_in_fifo,
    output  reg [31 : 0]    data_fifo
);

    reg     [15 : 0]    fifo_match_list;
    reg     [ 3 : 0]    match_entry;

    integer temp_j;

    always @(*) begin
        for (integer i = 0; i < 16; i = i + 1) begin
            temp_j = (i + ptr_old) & 32'd15;
            fifo_match_list[i] = (csrfifo[temp_j].csrWr == 1 && csrfifo[temp_j].csrWr_addr == rd_addr)? 1 : 0;
        end

        casez (fifo_match_list)
            16'b1???_????_????_????:    {match_entry, find_in_fifo}     =   {4'd15, 1'b1};
            16'b01??_????_????_????:    {match_entry, find_in_fifo}     =   {4'd14, 1'b1};
            16'b001?_????_????_????:    {match_entry, find_in_fifo}     =   {4'd13, 1'b1};
            16'b0001_????_????_????:    {match_entry, find_in_fifo}     =   {4'd12, 1'b1};
            16'b0000_1???_????_????:    {match_entry, find_in_fifo}     =   {4'd11, 1'b1};
            16'b0000_01??_????_????:    {match_entry, find_in_fifo}     =   {4'd10, 1'b1};
            16'b0000_001?_????_????:    {match_entry, find_in_fifo}     =   {4'd9 , 1'b1};
            16'b0000_0001_????_????:    {match_entry, find_in_fifo}     =   {4'd8 , 1'b1};

            16'b0000_0000_1???_????:    {match_entry, find_in_fifo}     =   {4'd7 , 1'b1};
            16'b0000_0000_01??_????:    {match_entry, find_in_fifo}     =   {4'd6 , 1'b1};
            16'b0000_0000_001?_????:    {match_entry, find_in_fifo}     =   {4'd5 , 1'b1};
            16'b0000_0000_0001_????:    {match_entry, find_in_fifo}     =   {4'd4 , 1'b1};
            16'b0000_0000_0000_1???:    {match_entry, find_in_fifo}     =   {4'd3 , 1'b1};
            16'b0000_0000_0000_01??:    {match_entry, find_in_fifo}     =   {4'd2 , 1'b1};
            16'b0000_0000_0000_001?:    {match_entry, find_in_fifo}     =   {4'd1 , 1'b1};
            16'b0000_0000_0000_0001:    {match_entry, find_in_fifo}     =   {4'd0 , 1'b1};

            default:                    {match_entry, find_in_fifo}     =   {4'd0 , 1'b0};
        endcase

        data_fifo  =   (match_entry + ptr_old >= 16)? csrfifo[match_entry + ptr_old - 16].csrWr_data : csrfifo[match_entry + ptr_old].csrWr_data;
    end

endmodule