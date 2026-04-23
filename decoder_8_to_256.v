module decoder_8_to_256 (
    input  wire [7:0]  challenge_in,
    input  wire        enable_in,
    output reg  [255:0] decoded_out
);
    always @(*) begin
        decoded_out = 256'b0; // Default: all off
        if (enable_in) begin
            decoded_out[challenge_in] = 1'b1;
        end
    end
endmodule