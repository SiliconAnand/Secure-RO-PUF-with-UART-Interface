`timescale 1ns/1ps
module ro_puf_tb_multi;
    parameter N = 1;
    parameter CLK_PERIOD = 20;
    parameter COUNT_WINDOW = 1000;

    reg clk, en, init_clk;
    reg [N*8-1:0] sela_vec, selb_vec;

    wire [N-1:0] res_vec;
    wire [N*32-1:0] cnta_vec, cntb_vec;
    wire [255:0] decout, ro_out;

    ro_puf_top_multi #(.N(N)) DUT (
        .clk(clk), .en(en),
        .sela_vec(sela_vec), .selb_vec(selb_vec),
        .init_clk(init_clk),
        .res_vec(res_vec), .cnta_vec(cnta_vec), .cntb_vec(cntb_vec),
        .decout(decout), .ro_out(ro_out)
    );

    initial begin clk = 0; forever #(CLK_PERIOD/2) clk = ~clk; end

    integer i;
    initial begin
        init_clk = 1; en = 0;
        // Packing in reverse order for [N-1]:0 down to 0
        sela_vec = {8'b00000100};
        selb_vec = {8'b00010000};
        #20;
        init_clk = 0; en = 1;
        #COUNT_WINDOW;
        en = 0; init_clk = 1; #10;
        for (i = 0; i < N; i = i + 1) begin
            $display("CRP%0b: sela=%0d selb=%0d cnta=%0h cntb=%0h res=%b",
                i, sela_vec[i*8+:8], selb_vec[i*8+:8],
                cnta_vec[i*32+:32], cntb_vec[i*32+:32], res_vec[i]);
        end
        #1000; $finish;
    end
endmodule
