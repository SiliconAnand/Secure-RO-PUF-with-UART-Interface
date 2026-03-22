`timescale 1ns/1ps
module ro_puf_top_multi #(
    parameter N = 1
)(
    input wire clk,
    input wire en,
    input wire [N*8-1:0] sela_vec,
    input wire [N*8-1:0] selb_vec,
    input wire init_clk,
    output wire [N-1:0] res_vec,
    output wire [N*32-1:0] cnta_vec,
    output wire [N*32-1:0] cntb_vec,
    output wire [255:0] decout,
    output wire [255:0] ro_out
);

    // Arrays for decoder outputs
    wire [255:0] decout_a [0:N-1];
    wire [255:0] decout_b [0:N-1];

    // Per-CRP logic in generate block
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : crp
            wire [7:0] sela = sela_vec[i*8 +: 8];
            wire [7:0] selb = selb_vec[i*8 +: 8];
            wire mux_out_a, mux_out_b;
            wire [31:0] cnta, cntb;
            wire res;

            decoder_8_to_256 D_A (
                .challenge_in(sela),
                .enable_in(en),
                .decoded_out(decout_a[i])
            );
            decoder_8_to_256 D_B (
                .challenge_in(selb),
                .enable_in(en),
                .decoded_out(decout_b[i])
            );
            mux_256_to_1 MUX_A (
                .input_256(ro_out),
                .select_8(sela),
                .mux_out(mux_out_a)
            );
            mux_256_to_1 MUX_B (
                .input_256(ro_out),
                .select_8(selb),
                .mux_out(mux_out_b)
            );
            counter_32 CNT_A (
                .clk_in(clk),
                .ro_freq_in(mux_out_a),
                .reset(init_clk),
                .count_out(cnta)
            );
            counter_32 CNT_B (
                .clk_in(clk),
                .ro_freq_in(mux_out_b),
                .reset(init_clk),
                .count_out(cntb)
            );
            comparator_puf COMP (
                .count_a_in(cnta),
                .count_b_in(cntb),
                .response(res)
            );
            assign cnta_vec[i*32 +: 32] = cnta;
            assign cntb_vec[i*32 +: 32] = cntb;
            assign res_vec[i] = res;
        end
    endgenerate

    // Proper decoder output combination for RO array enable input
    reg [255:0] combined_enable;
    integer idx;
    always @(*) begin
        combined_enable = 256'b0;
        for (idx = 0; idx < N; idx = idx + 1)
            combined_enable = combined_enable | decout_a[idx] | decout_b[idx];
    end
    assign decout = combined_enable;

    ring_oscillator_array_256 RO_ARRAY (
        .enable_in(decout),
        .ro_out_freqs(ro_out)
    );
endmodule
