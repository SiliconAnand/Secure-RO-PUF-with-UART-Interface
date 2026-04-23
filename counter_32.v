`timescale 1ns/1ps

module counter_32 (
    input wire clk_in,  // The RO frequency signal (the 'clock')
    input wire reset,   // Asynchronous reset from BTNU/Controller
    output reg [31:0] count_out
);
    
    // We use the RO output (mux_out_a/b) as the clock for this process.
    // Every time the RO completes a cycle, the counter increments.
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            count_out <= 32'h0;
        end else begin
            count_out <= count_out + 1;
        end
    end
    
endmodule