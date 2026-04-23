module puf_controller #(
    parameter WINDOW = 100000000
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    
    // PUF Hardware Interface
    output reg         puf_en,
    output reg  [7:0]  sela,
    output reg  [7:0]  selb,
    input  wire        puf_res,
    output reg         comp_enable,

    // FIFO Interface
    input  wire        fifo_full,
    output reg         fifo_wr_en,
    output reg  [7:0]  fifo_data_in
);

    reg [31:0] timer;
    reg [7:0]  challenge_idx;
    reg [2:0]  byte_sel; // Increased to 3 bits to handle 5 bytes
    reg [7:0]  wait_cnt;
    reg        puf_res_latched;

    localparam IDLE=0, MEASURE=1, WAIT=2, SEND=3;
    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            puf_en <= 0;
            fifo_wr_en <= 0;
            comp_enable <= 0;
            timer <= 0;
            challenge_idx <= 0;
            wait_cnt <= 0;
        end else begin
            fifo_wr_en <= 0; 
            comp_enable <= 0;

            case(state)
                IDLE: begin
                    puf_en <= 0;
                    timer <= 0;
                    wait_cnt <= 0;
                    if (start) begin
                        challenge_idx <= 0;
                        state <= MEASURE;
                    end
                end

                MEASURE: begin
                    puf_en <= 1;
                    sela <= challenge_idx;
                    selb <= ~challenge_idx; 
                    if (timer >= WINDOW-1) begin
                        timer <= 0;
                        puf_en <= 0;
                        state <= WAIT;
                    end else begin
                        timer <= timer + 1;
                    end
                end

                WAIT: begin
                    comp_enable <= 1; 
                    if (wait_cnt >= 20) begin // Increased wait for CDC stability
                        wait_cnt <= 0;
                        puf_res_latched <= puf_res; 
                        byte_sel <= 0;
                        state <= SEND;
                    end else begin
                        wait_cnt <= wait_cnt + 1;
                    end
                end

                SEND: begin
                    if (!fifo_full) begin
                        fifo_wr_en <= 1;
                        case(byte_sel)
                            0: fifo_data_in <= 8'd82; // 'R'
                            1: fifo_data_in <= 8'd58; // ':'
                            // FIXED: puf_res=1 now sends '1' (49), puf_res=0 sends '0' (48)
                            2: fifo_data_in <= puf_res_latched ? 8'd49 : 8'd48; 
                            3: fifo_data_in <= 8'd13; // '\r' (Carriage Return) - FIXES STAIRCASE
                            4: fifo_data_in <= 8'd10; // '\n' (Line Feed)
                            default: fifo_data_in <= 8'd0;
                        endcase

                        if (byte_sel == 4) begin // Changed to 4 to accommodate \r
                            byte_sel <= 0;
                            if (challenge_idx == 8'hFF) begin 
                                state <= IDLE;
                            end else begin
                                challenge_idx <= challenge_idx + 1;
                                state <= MEASURE;
                            end
                        end else begin
                            byte_sel <= byte_sel + 1;
                        end
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule