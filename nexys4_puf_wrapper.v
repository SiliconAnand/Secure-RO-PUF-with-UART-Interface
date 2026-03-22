module nexys4_puf_wrapper (
    input  wire CLK100MHZ,
    input  wire [15:0] SW,      
    input  wire BTNC,           
    input  wire BTNU,           
    output wire [15:0] LED,     
    output wire [7:0] AN,       
    output wire [6:0] SEG       
);

    wire [7:0] sela = SW[7:0];
    wire [7:0] selb = SW[15:8]; 
    wire [31:0] count_a, count_b;
    wire [0:0] puf_res_vec; // N=1 result

// Updated ILA instantiation with correct signal names
ila_0 your_puf_ila (
    .clk(CLK100MHZ),   // Connect to your top-level 100MHz clock
    .probe0(count_a),  // Connect to the 32-bit counter from PUF Instance A
    .probe1(count_b)   // Connect to the 32-bit counter from PUF Instance B
);
    ro_puf_top_multi #(.N(1)) PUF_CORE (
        .clk(CLK100MHZ),
        .en(BTNC),
        .sela_vec(sela),
        .selb_vec(selb),
        .init_clk(BTNU),
        .res_vec(puf_res_vec),
        .cnta_vec(count_a),
        .cntb_vec(count_b),
        .decout(), 
        .ro_out()  
    );

    assign LED[0] = puf_res_vec[0];
    assign LED[15:1] = count_a[14:0]; // Flickering shows oscillation

    assign AN = 8'b11111110; 
    seven_seg_hex DEBUG_DISP (
        .hex(count_a[3:0]), 
        .seg(SEG)
    );
endmodule

module seven_seg_hex (
    input  wire [3:0] hex,
    output reg  [6:0] seg
);
    always @(*) begin
        case(hex)
            4'h0: seg = 7'b1000000; 4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100; 4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001; 4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010; 4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000; 4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000; 4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110; 4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110; 4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end
endmodule