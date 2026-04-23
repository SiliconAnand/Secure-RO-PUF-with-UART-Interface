`timescale 1ns/1ps

module comparator_puf (
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [31:0] count_a_in,
    input wire [31:0] count_b_in,
    output reg response
);

    always @(posedge clk) begin
        if (reset) begin
            response <= 1'b0;
        end else if (enable) begin
            // Standard PUF Logic: 
            // If A is faster (higher count), Response is 1.
            // If B is faster (higher count), Response is 0.
            if (count_a_in > count_b_in)
                response <= 1'b1;
            else if (count_a_in < count_b_in)
                response <= 1'b0;
            else
                response <= 1'b0; // Default to 0 for a tie
        end
    end

endmodule