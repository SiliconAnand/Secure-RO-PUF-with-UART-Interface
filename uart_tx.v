module uart_tx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       rst,       // Added hardware reset (BTNU)
    input  wire       tx_start,  // Triggered by FIFO-to-UART handshake
    input  wire [7:0] data_in,   // Data from FIFO dout
    output reg        tx_pin,
    output reg        tx_active,
    output reg        tx_done    // High for one cycle after STOP bit ends
);

    // Calculate bit period and counter width automatically
    localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;
    localparam CNT_WIDTH  = $clog2(BIT_PERIOD);

    reg [CNT_WIDTH-1:0] clk_count;
    reg [3:0]           bit_index;
    reg [7:0]           tx_data;
    reg [1:0]           state;

    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            tx_pin    <= 1'b1;
            tx_active <= 1'b0;
            tx_done   <= 1'b0;
            clk_count <= 0;
            bit_index <= 0;
            tx_data   <= 8'h00;
        end else begin
            tx_done <= 1'b0; // Default state

            case (state)
                IDLE: begin
                    tx_pin    <= 1'b1;
                    tx_active <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;
                    
                    if (tx_start) begin
                        tx_data   <= data_in;
                        tx_active <= 1'b1;
                        state     <= START;
                    end
                end

                START: begin
                    tx_pin <= 1'b0; // Start bit (Low)
                    if (clk_count < BIT_PERIOD - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 0;
                        state     <= DATA;
                    end
                end

                DATA: begin
                    tx_pin <= tx_data[bit_index]; // Send LSB first
                    if (clk_count < BIT_PERIOD - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1'b1;
                        end else begin
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx_pin <= 1'b1; // Stop bit (High)
                    if (clk_count < BIT_PERIOD - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        tx_done   <= 1'b1; // Signal finished to the controller
                        tx_active <= 1'b0;
                        state     <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule