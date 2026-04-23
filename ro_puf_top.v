`timescale 1ns/1ps

module ro_puf_top_multi (
    input  wire        clk,          // System Clock (100MHz)
    input  wire        en,           // Global Enable from Controller
    input  wire [7:0]  sela_vec,     // Challenge A (8-bit)
    input  wire [7:0]  selb_vec,     // Challenge B (8-bit)
    input  wire        init_clk,     // Reset/Initialize Counters (BTNU)
    input  wire        comp_enable,  // Enable Comparator after measurement

    output wire        res,          // Final PUF bit (0 or 1)
    output wire [31:0] cnta_out,     // Debug: Counter A value
    output wire [31:0] cntb_out      // Debug: Counter B value
);

    // =====================================================
    // Internal Signals
    // =====================================================
    wire [255:0] ro_out;
    wire mux_out_a, mux_out_b;
    
    // Internal synchronization registers (Marked for ILA visibility)
    (* mark_debug = "true" *) reg [31:0] cnta_sync;
    (* mark_debug = "true" *) reg [31:0] cntb_sync;
    
    // Falling edge detection for 'en' to capture stable counts
    reg en_delayed;
    always @(posedge clk) en_delayed <= en;
    wire capture_trigger = (en_delayed && !en); // High for 1 cycle when race ends

    // =====================================================
    // 1. Ring Oscillator Array (256 Instances)
    // =====================================================
    // Replicates 'en' to all ROs. DONT_TOUCH in sub-module prevents trimming.
    ring_oscillator_array_256 RO_ARRAY (
        .enable_in({256{en}}), 
        .ro_out_freqs(ro_out)
    );

    // =====================================================
    // 2. Multiplexers (Select 2 ROs out of 256)
    // =====================================================
    mux_256_to_1 MUX_A (
        .input_256(ro_out),
        .select_8(sela_vec),
        .mux_out(mux_out_a)
    );

    mux_256_to_1 MUX_B (
        .input_256(ro_out),
        .select_8(selb_vec),
        .mux_out(mux_out_b)
    );

    // =====================================================
    // 3. Asynchronous Counters (Clocked by ROs)
    // =====================================================
    // These wires must be connected to internal logic to avoid being deleted
    wire [31:0] raw_cnta, raw_cntb;

    counter_32 CNT_A (
        .clk_in(mux_out_a),  // RO frequency acts as the clock
        .reset(init_clk),
        .count_out(raw_cnta)
    );

    counter_32 CNT_B (
        .clk_in(mux_out_b),  // RO frequency acts as the clock
        .reset(init_clk),
        .count_out(raw_cntb)
    );

    // =====================================================
    // 4. Clock Domain Crossing (CDC) Synchronization
    // =====================================================
    // We only update the sync registers when the race is OVER.
    // This provides a "frozen" snapshot for the ILA and Comparator.
    always @(posedge clk) begin
        if (init_clk) begin
            cnta_sync <= 32'd0;
            cntb_sync <= 32'd0;
        end else if (capture_trigger) begin
            cnta_sync <= raw_cnta;
            cntb_sync <= raw_cntb;
        end
    end

    // Drive outputs for the Top Wrapper / ILA
    assign cnta_out = cnta_sync;
    assign cntb_out = cntb_sync;

    // =====================================================
    // 5. Comparator (The Decision Maker)
    // =====================================================
    comparator_puf COMP (
        .clk(clk),
        .reset(init_clk),
        .enable(comp_enable),
        .count_a_in(cnta_sync),
        .count_b_in(cntb_sync),
        .response(res)
    );

endmodule