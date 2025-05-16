module shifter (rd, rs, imm, mode);
    output [15:0] rd;
    input [15:0] rs;
    input [1:0] mode;
    input [15:0] imm;

    wire [15:0] s1_l, s2_l, s4_l, s8_l, s1_r, s2_r, s4_r, s8_r, r1_r, r2_r, r4_r, r8_r;


    //sll
    assign s1_l = imm[0] ? {rs[14:0], 1'b0} : rs;
    assign s2_l = imm[1] ? {s1_l[13:0], 2'b00} : s1_l;
    assign s4_l = imm[2] ? {s2_l[11:0], 4'b0000} : s2_l;
    assign s8_l = imm[3] ? {s4_l[7:0], 8'b00000000} : s4_l;

    //sra
    assign s1_r = imm[0] ? {rs[15], rs[15:1]} : rs;
    assign s2_r = imm[1] ? {{2{rs[15]}}, s1_r[15:2]} : s1_r;
    assign s4_r = imm[2] ? {{4{rs[15]}}, s2_r[15:4]} : s2_r;
    assign s8_r = imm[3] ? {{8{rs[15]}}, s4_r[15:8]} : s4_r;

    //ror
    assign r1_r = imm[0] ? {rs[0], rs[15:1]} : rs;
    assign r2_r = imm[1] ? {r1_r[1:0], r1_r[15:2]} : r1_r;
    assign r4_r = imm[2] ? {r2_r[3:0], r2_r[15:4]} : r2_r;
    assign r8_r = imm[3] ? {r4_r[7:0], r4_r[15:8]} : r4_r;


    //mux based on mode - 00: sll, 01: sra, 10: ror
    assign rd = mode[0] ? s8_r : mode[1] ? r8_r : s8_l;

endmodule