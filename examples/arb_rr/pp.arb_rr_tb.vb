
@pp_include "autoloads/v/tb.pp"
@pp_include "autoloads/v/utils.pp"

module arb_rr_tb;

GenClk clk, 5;
GenRst rst_n, 100;

`define tick @(posedge clk)

parameter LOG2_N=2;
parameter N=1<<LOG2_N;

reg [N-1:0] reqs;
wire [N-1:0] gnts;


initial begin
   wait(rst_n==1);
   @(posedge clk);
   $display($time, " Reset deaserted");

   reqs <= 'b0100;
   waitfor(gnts != 0);
   $display($time, " For reqs=%b Got gnts=%b", reqs, gnts);

   reqs <= 'b0000;
   waitfor(gnts == 0);
   $display($time, " For reqs=%b Got gnts=%b", reqs, gnts);

   reqs <= 'b0110;
   waitfor(gnts != 0);
   $display($time, " For reqs=%b Got gnts=%b", reqs, gnts);

   reqs <= 'b0000;
   waitfor(gnts == 0);
   $display($time, " For reqs=%b Got gnts=%b", reqs, gnts);

   `tick;
   $finish;
end

arb_rr arb_rr0 (.*);

endmodule
