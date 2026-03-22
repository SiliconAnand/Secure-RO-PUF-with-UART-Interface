module ring_oscillator_array_256 (
    input  wire [255:0] enable_in,
    output wire [255:0] ro_out_freqs
);

    genvar i;
    generate
        for (i = 0; i < 256; i = i + 1) begin : ro_gen
            ro_cell RO_INST (
                .enable(enable_in[i]),
                .out(ro_out_freqs[i])
            );
        end
    endgenerate

endmodule