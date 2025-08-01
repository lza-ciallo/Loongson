module FREELIST (
    input   [63 : 0]    free_list,
    input   [ 4 : 0]    Rd              [2 : 0],
    output  [ 5 : 0]    Pd              [2 : 0],
    output              full_prf
);

    reg     [ 5 : 0]    Pd_r            [2 : 0];
    generate
        for (genvar i = 0; i < 3; i = i + 1) begin
            assign  Pd[i]       =   (Rd[i] == 0)? 0 : Pd_r[i];
        end
    endgenerate

    wire    [63 : 0]    free_list_wire  [2 : 0];
    assign  free_list_wire[0]   =   free_list;
    assign  free_list_wire[1]   =   free_list_wire[0] & ~(32'd1 << Pd[0]);
    assign  free_list_wire[2]   =   free_list_wire[1] & ~(32'd1 << Pd[1]);

    wire                full_prf_wire   [2 : 0];
    generate
        for (genvar i = 0; i < 3; i = i + 1) begin
            assign  full_prf_wire[i]    =   (free_list_wire[i] == 64'b0)? 1 : 0;
        end
    endgenerate
    assign  full_prf    =   full_prf_wire[2] | full_prf_wire[1] | full_prf_wire[0];

    generate
        for (genvar i = 0; i < 3; i = i + 1) begin
            always @(*) begin
                casez (free_list_wire[i])
                    64'b????_????_????_????_????_????_????_????_????_????_????_????_????_????_????_???1:    Pd_r[i] =   6'd0;
                    64'b????_????_????_????_????_????_????_????_????_????_????_????_????_????_????_??10:    Pd_r[i] =   6'd1;
                    64'b????_????_????_????_????_????_????_????_????_????_????_????_????_????_????_?100:    Pd_r[i] =   6'd2;
                    64'b????_????_????_????_????_????_????_????_????_????_????_????_????_????_????_1000:    Pd_r[i] =   6'd3;
                    64'b????_????_????_????_????_????_????_????_????_????_????_????_????_????_???1_0000:    Pd_r[i] =   6'd4;
                    64'b????_????_????_????_????_????_????_????_????_????_????_????_????_????_??10_0000:    Pd_r[i] =   6'd5;
                    64'b????_????_????_????_????_????_????_????_????_????_????_????_????_????_?100_0000:    Pd_r[i] =   6'd6;
                    64'b????_????_????_????_????_????_????_????_????_????_????_????_????_????_1000_0000:    Pd_r[i] =   6'd7;

                    64'b????_????_????_????_????_????_????_????_????_????_????_????_????_???1_0000_0000:    Pd_r[i] =   6'd8;
                    64'b????_????_????_????_????_????_????_????_????_????_????_????_????_??10_0000_0000:    Pd_r[i] =   6'd9;
                    64'b????_????_????_????_????_????_????_????_????_????_????_????_????_?100_0000_0000:    Pd_r[i] =   6'd10;
                    64'b????_????_????_????_????_????_????_????_????_????_????_????_????_1000_0000_0000:    Pd_r[i] =   6'd11;
                    64'b????_????_????_????_????_????_????_????_????_????_????_????_???1_0000_0000_0000:    Pd_r[i] =   6'd12;
                    64'b????_????_????_????_????_????_????_????_????_????_????_????_??10_0000_0000_0000:    Pd_r[i] =   6'd13;
                    64'b????_????_????_????_????_????_????_????_????_????_????_????_?100_0000_0000_0000:    Pd_r[i] =   6'd14;
                    64'b????_????_????_????_????_????_????_????_????_????_????_????_1000_0000_0000_0000:    Pd_r[i] =   6'd15;

                    64'b????_????_????_????_????_????_????_????_????_????_????_???1_0000_0000_0000_0000:    Pd_r[i] =   6'd16;
                    64'b????_????_????_????_????_????_????_????_????_????_????_??10_0000_0000_0000_0000:    Pd_r[i] =   6'd17;
                    64'b????_????_????_????_????_????_????_????_????_????_????_?100_0000_0000_0000_0000:    Pd_r[i] =   6'd18;
                    64'b????_????_????_????_????_????_????_????_????_????_????_1000_0000_0000_0000_0000:    Pd_r[i] =   6'd19;
                    64'b????_????_????_????_????_????_????_????_????_????_???1_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd20;
                    64'b????_????_????_????_????_????_????_????_????_????_??10_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd21;
                    64'b????_????_????_????_????_????_????_????_????_????_?100_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd22;
                    64'b????_????_????_????_????_????_????_????_????_????_1000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd23;

                    64'b????_????_????_????_????_????_????_????_????_???1_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd24;
                    64'b????_????_????_????_????_????_????_????_????_??10_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd25;
                    64'b????_????_????_????_????_????_????_????_????_?100_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd26;
                    64'b????_????_????_????_????_????_????_????_????_1000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd27;
                    64'b????_????_????_????_????_????_????_????_???1_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd28;
                    64'b????_????_????_????_????_????_????_????_??10_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd29;
                    64'b????_????_????_????_????_????_????_????_?100_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd30;
                    64'b????_????_????_????_????_????_????_????_1000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd31;

                    64'b????_????_????_????_????_????_????_???1_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd32;
                    64'b????_????_????_????_????_????_????_??10_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd33;
                    64'b????_????_????_????_????_????_????_?100_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd34;
                    64'b????_????_????_????_????_????_????_1000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd35;
                    64'b????_????_????_????_????_????_???1_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd36;
                    64'b????_????_????_????_????_????_??10_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd37;
                    64'b????_????_????_????_????_????_?100_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd38;
                    64'b????_????_????_????_????_????_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd39;

                    64'b????_????_????_????_????_???1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd40;
                    64'b????_????_????_????_????_??10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd41;
                    64'b????_????_????_????_????_?100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd42;
                    64'b????_????_????_????_????_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd43;
                    64'b????_????_????_????_???1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd44;
                    64'b????_????_????_????_??10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd45;
                    64'b????_????_????_????_?100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd46;
                    64'b????_????_????_????_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd47;

                    64'b????_????_????_???1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd48;
                    64'b????_????_????_??10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd49;
                    64'b????_????_????_?100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd50;
                    64'b????_????_????_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd51;
                    64'b????_????_???1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd52;
                    64'b????_????_??10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd53;
                    64'b????_????_?100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd54;
                    64'b????_????_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd55;

                    64'b????_???1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd56;
                    64'b????_??10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd57;
                    64'b????_?100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd58;
                    64'b????_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd59;
                    64'b???1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd60;
                    64'b??10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd61;
                    64'b?100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd62;
                    64'b1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000:    Pd_r[i] =   6'd63;

                    default:                                                                                Pd_r[i] =   6'd0;
                endcase
            end
        end
    endgenerate

endmodule