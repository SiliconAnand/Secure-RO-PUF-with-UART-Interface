`timescale 1ns/1ps
// --- File: mux_256_to_1.v ---
module mux_256_to_1 (
    input wire [255:0] input_256,
    input wire [7:0] select_8,
    output wire mux_out // Changed to wire, as select_8 drives it combinatorially
);
    // Standard 256-to-1 MUX implemented using continuous assignment
    assign mux_out = input_256[select_8];
endmodule