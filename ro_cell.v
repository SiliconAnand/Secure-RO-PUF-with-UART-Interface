`timescale 1ns/1ps
module ro_cell (
    input  wire enable,
    output wire out
);

    (* dont_touch = "yes" *) wire [4:0] w;

    assign w[0] = ~(enable & w[4]);
    assign w[1] = ~w[0];
    assign w[2] = ~w[1];
    assign w[3] = ~w[2];
    assign w[4] = ~w[3];

    assign out = w[4];

endmodule