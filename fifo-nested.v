`timescale 1ns / 1ps


module FIFO_nestedfor(clk, rst, din,  we, re, dout, valid_out);
    parameter DW = 8;
    parameter AW = 8;

    input clk, rst, we, re;
    input  [DW-1:0] din;
    output [2*DW-1:0] dout;
    output valid_out;

    reg [AW-1:0] rpointerA, rpointerB, wpointer;
    reg valid_out;

    generic_dpram #(AW,DW) RAM0 (
        .rclk(clk),
        .wclk(clk),
        .rrst(rst),
        .wrst(rst),
        .rce(1),
        .wce(1),
        .oe(re),
        .we(we),
        .raddr(rpointerA),
        .waddr(wpointer),
        .di(din),
        .do(dout[DW-1:0]));

    generic_dpram #(AW,DW)  RAM1 (
        .rclk(clk),
        .wclk(clk),
        .rrst(rst),
        .wrst(rst),
        .rce(1),
        .wce(1),
        .oe(re),
        .we(we),
        .raddr(rpointerB),
        .waddr(wpointer),
        .di(din),
        .do(dout[DW*2-1:DW]));


    always @(posedge clk) begin
        if (rst) begin
            rpointerA <= 0;
            rpointerB <= 1;
            wpointer  <= 0;
            valid_out <= 0;
        end
        else begin
            if (we) begin
                wpointer <= wpointer + 1;
            end
            if (re) begin
                if ((rpointerB == wpointer) &&  (rpointerA + 1== wpointer)) begin
                    // we have generated the last of the ordered pairs
                    valid_out <= 0;
                end
                else if (rpointerB + 1 == wpointer) begin
                    if (rpointerA + 1 == wpointer) begin
                        valid_out <= 0;
                    end
                    else begin
                        // we have generated the last combination with the current A
                        rpointerB <= rpointerA + 2;
                        rpointerA <= rpointerA + 1;
                        valid_out <= 1;
                    end
                end
                else begin
                    rpointerB <= rpointerB + 1;
                    valid_out <= 1;
                end
            end
        end
    end
endmodule

module FIFO_nestedfor_TB();
    parameter DW = 8;
    parameter AW = 8;

    reg  clk, rst, we, re;
    reg  [DW-1:0] din;
    wire [2*DW-1:0] dout;
    wire valid_out;

    integer i;

    FIFO_nestedfor #(DW,AW) DUT (clk, rst, din,  we, re, dout,valid_out);

    always #5 clk = ~clk ;

    always @(posedge clk) begin
        $display("%d we=%b re=%b din=%h dout=%h vout=%h rpointerA=%h, rpointerB=%h",
                    $time,we,re,din,dout,valid_out,
                    DUT.rpointerA,DUT.rpointerB, DUT.wpointer);
    end


    initial begin
        // Initialize Inputs
        clk = 0; rst = 0; din = 0;  we = 0; re = 0;

        @(negedge clk) rst = 1;
        @(negedge clk) rst = 0;

        @(negedge clk) begin din=8'hA1; we = 1; end
        @(negedge clk) begin din=8'hA2; we = 1; end
        @(negedge clk) begin din=8'hA3; we = 1; end
        @(negedge clk) begin din=8'hA4; we = 1; end
        @(negedge clk) begin we = 0; end

        @(negedge clk) begin re = 1; end
        for (i=0;i<20;i=i+1) @(negedge clk);

        // Wait 100 ns for global reset to finish
        @(negedge clk) $finish ;

    end

endmodule
