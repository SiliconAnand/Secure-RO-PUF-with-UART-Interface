module nexys4_puf_wrapper (
    input  wire CLK100MHZ,
    input  wire BTNC,       // Start Button
    input  wire BTNU,       // Reset Button
    output wire UART_TXD,
    output wire [15:0] LED
);

    // Internal Signals
    wire puf_en, comp_enable, puf_res;
    wire [7:0] sela, selb;
    wire [7:0] fifo_din;
    wire [7:0] fifo_dout;
    wire fifo_wr_en, fifo_empty, fifo_full;
    wire uart_busy;
    
    // Internal wires for Counters (CRITICAL: Prevents Logic Trimming)
    wire [31:0] cnta_internal, cntb_internal;

    // Reset Synchronization (To prevent mechanical button bounce issues)
    reg sync_rst;
    always @(posedge CLK100MHZ) sync_rst <= BTNU;

    // Handshake Registers
    reg fifo_rd_en;
    reg fifo_rd_en_d; // Delayed version to match FIFO 1-clock latency

    // =====================================================
    // 1. PUF CONTROLLER
    // =====================================================
    puf_controller #( .WINDOW(20000000) ) CTRL (
        .clk(CLK100MHZ),
        .rst(sync_rst),
        .start(BTNC),
        .puf_en(puf_en),
        .sela(sela),
        .selb(selb),
        .puf_res(puf_res),
        .comp_enable(comp_enable),
        .fifo_full(fifo_full),
        .fifo_wr_en(fifo_wr_en),
        .fifo_data_in(fifo_din)
    );

    // =====================================================
    // 2. RO-PUF CORE
    // =====================================================
    ro_puf_top_multi CORE (
        .clk(CLK100MHZ),
        .en(puf_en),
        .sela_vec(sela),
        .selb_vec(selb),
        .init_clk(sync_rst), // Use synchronized reset
        .comp_enable(comp_enable),
        .res(puf_res),
        .cnta_out(cnta_internal), // CONNECTED: Now ILA can see these
        .cntb_out(cntb_internal)  // CONNECTED: Now ILA can see these
    );

    // =====================================================
    // 3. HANDSHAKE LOGIC (FIFO TO UART)
    // =====================================================
    always @(posedge CLK100MHZ) begin
        if (sync_rst) begin
            fifo_rd_en   <= 1'b0;
            fifo_rd_en_d <= 1'b0;
        end else begin
            fifo_rd_en_d <= fifo_rd_en;

            // Trigger read if: FIFO has data AND UART is idle AND no read is currently active
            if (!fifo_empty && !uart_busy && !fifo_rd_en) begin
                fifo_rd_en <= 1'b1;
            end else begin
                fifo_rd_en <= 1'b0;
            end
        end
    end

    // =====================================================
    // 4. FIFO GENERATOR (Standard Mode)
    // =====================================================
    fifo_generator_0 FIFO (
        .clk(CLK100MHZ),
        .srst(sync_rst),    
        .din(fifo_din),
        .wr_en(fifo_wr_en),
        .rd_en(fifo_rd_en),
        .dout(fifo_dout),
        .empty(fifo_empty),
        .full(fifo_full)
    );

    // =====================================================
    // 5. UART TRANSMITTER
    // =====================================================
    uart_tx #( .CLK_FREQ(100_000_000), .BAUD_RATE(115200) ) UART (
        .clk(CLK100MHZ),
        .rst(sync_rst),
        .tx_start(fifo_rd_en_d), // Starts exactly when FIFO data is valid on dout
        .data_in(fifo_dout),
        .tx_pin(UART_TXD),
        .tx_active(uart_busy),
        .tx_done()
    );

    // =====================================================
    // DEBUG LED MAPPING
    // =====================================================
    assign LED[0]  = puf_res;       // Current Result Bit
    assign LED[1]  = uart_busy;    // High when transmitting
    assign LED[2]  = !fifo_empty;  // High when data is waiting to be sent
    assign LED[3]  = puf_en;       // High during the RO Race
    assign LED[4]  = comp_enable;  // High during comparison
    assign LED[14] = sync_rst;     // Reset Status
    assign LED[15] = fifo_full;    // Warning: FIFO overflow

endmodule