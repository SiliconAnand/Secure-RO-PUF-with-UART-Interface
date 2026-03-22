`timescale 1ns/1ps
module counter_32 (
    input wire clk_in,       // Clock for internal flop updates (optional, for synchronizing count)
    input wire ro_freq_in,   // The actual signal to count
    input wire reset,
    output reg [31:0] count_out
);
    
    // The counter logic: Count the rising edge of the RO frequency signal (ro_freq_in)
    // while the reset is inactive.
    always @(posedge ro_freq_in or posedge reset) begin
        if (reset) begin
            count_out <= 32'h0;
        end else begin
            count_out <= count_out + 1;
        end
    end
    
endmodule