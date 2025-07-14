module DECODER (
    input   [12 : 0]    inst,
    output  [ 1 : 0]    Type,   // 00=ADD, 01=MUL, 10=LW, 11=SW
    output  [ 2 : 0]    Ra,
    output  [ 2 : 0]    Rb,
    output  [ 2 : 0]    Rw,
    output  [ 4 : 0]    Imm
);

    assign  Type    =   inst[12 : 11];
    assign  Ra      =   inst[ 7 :  5];
    assign  Rb      =   (Type == 2'b11)? inst[10 : 8] : inst[ 4 : 2];
    assign  Rw      =   (Type == 2'b11)?            0 : inst[10 : 8];
    assign  Imm     =   inst[ 4 :  0];

endmodule