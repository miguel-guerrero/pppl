
@pp_include "autoloads/v/tb.pp"
@pp_include "autoloads/v/utils.pp"

module arb_tb;

GenClk clk, 5;
GenRst rst_n, 100;

`define tick @(posedge clk)

reg req_0, req_1; 
wire gnt_0, gnt_1;

initial begin
   wait(rst_n==1);
   @(posedge clk);
   req_0 <= 1;
   waitfor(gnt_0==1);
   $display($time, " Got gnt_0");
   `tick;
   req_0 <= 0;
   req_1 <= 1;
   waitfor(gnt_1==1);
   $display($time, " Got gnt_1");
   req_1 <= 0;
   `tick;
   $finish;
end

arb arb_0 (.*);

endmodule
