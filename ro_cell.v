`timescale 1ns/1ps

module ro_cell (
    input  wire enable,
    output wire out
);

    // CRITICAL: ALLOW_COMBINATORIAL_LOOPS tells Vivado not to "fix" or delete the RO
    (* dont_touch = "yes" *)
    (* ALLOW_COMBINATORIAL_LOOPS = "true" *)
    wire [4:0] w;

    // Stage 0: NAND Gate (Enable/Disable logic)
    assign w[0] = ~(enable & w[4]);
    
    // Stages 1-4: Inverters
    assign w[1] = ~w[0];
    assign w[2] = ~w[1];
    assign w[3] = ~w[2];
    assign w[4] = ~w[3];

    // Output the final stage
    assign out = w[4];

endmodule