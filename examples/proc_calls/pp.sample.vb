
% # "example of how to include a local perl library file"
% perl_include "functions.pl"; 

@pp_include "autoloads/v/tb.pp"

module top;

% $semip = my_func();
GenClk clk, ${semip};
GenRst rst_n, 95;
GenRstMon rst_n;

initial begin
   #9000;
   $display($time," DONE");
   $finish;
end

ProcDef(min, in [15:0] x, in[15:0] y, in [15:0] z, out [15:0] res)
   res = x;
   `tick;
   if (y < res) res = y;
   `tick;
   if (z < res) res = z;
ProcDefEnd %%

ProcDef(max, in [15:0] x, in[15:0] y, in [15:0] z, out [15:0] res)
   if (x > y) res = x;
   else       res = y;
   `tick;
   if (z > res) res = z;
ProcDefEnd


SmBegin
   reg [15:0] min0 = 'b0;
   reg [15:0] max0 = 'b0;
   reg [3:0] cnt = 4'b0;
SmForever

   do begin
       ProcStart(min, cnt, 5, 10, min0);
       ProcStart(max, cnt, 5, 10, max0);
      `tick;
       ProcJoin(min, max);
       // $display($time, " min=%d max=%d cnt=%d", min0, max0, cnt);
       cnt = cnt + 1;
      `tick;
   end while (cnt < 20);

   `tick;
   cnt = 0;
SmEnd

always @(posedge clk) begin
   if (~min__go & min__done)
      $display($time, " min=%d cnt=%d", min__res, cnt);
   if (~max__go & max__done)
      $display($time, " max=%d cnt=%d", max__res, cnt);
end

initial begin
    $dumpfile("tb.vcd");
    $dumpvars;
end

endmodule
