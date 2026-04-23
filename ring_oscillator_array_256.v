module ring_oscillator_array_256 (
    input  wire [255:0] enable_in,
    output wire [255:0] ro_out_freqs
);

    genvar i;
    generate
        for (i = 0; i < 256; i = i + 1) begin : ro_gen
            // CRITICAL: DONT_TOUCH prevents Vivado from optimizing the loops away
            // KEEP_HIERARCHY ensures the placement remains unique for each RO
            (* DONT_TOUCH = "yes" *)
            (* KEEP_HIERARCHY = "yes" *)
            ro_cell RO_INST (
                .enable(enable_in[i]),
                .out(ro_out_freqs[i])
            );
        end
    endgenerate

endmodule