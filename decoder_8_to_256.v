module decoder_8_to_256 (
    input wire [7:0] challenge_in,
    input wire enable_in,
    output reg [255:0] decoded_out
);
    // Standard one-hot decoder logic
    always @(challenge_in or enable_in) begin
        decoded_out = 256'b0;
        if (enable_in) begin
            // Set the bit corresponding to the challenge_in value
            decoded_out[challenge_in] = 1'b1;
        end
    end
endmodule