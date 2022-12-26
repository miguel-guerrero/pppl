

Library contents:

v/tb
--------------------------------------------------------------------------

NAME
   GenClk - generate a clock in a testbench

SYNTAX
   % pp_include "v/tb.pp";
   ...
   GenClk clk_name, semiperiod

DESCRIPTION
   Generates a clock with the signal name 'clk_name' and period of
   2*semiperiod. The clock starts high. It has its first negedge
   at time 'semiperiod' and its first posedge and '2*semiperiod'

EXAMPLE
   % pp_include "v/tb.pp";
   ...
   GenClk clock, 5

   Generates a 10 ns clock named 'clock'. 
   The code may translate to something like:

   reg clock;
   initial begin
      clock <= 1;
      forever begin
         #5;
         clock <= ~clock;
      end
   end

SEE ALSO
   GenRst

-------------------

NAME
   GenRst - generate a reset generating signal in a testbench

SYNTAX
   % pp_include "v/tb.pp";
   ...
   GenRst reset_name, reset_time [, active_value]

DESCRIPTION
   Generates a reset signal with the signal name 'reset_name' 
   This signal takes the value 'active_value' during 'reset_time'
   and then it is negated (assigned ~active_value) for the rest
   of the simulation

   if active_value is ommited it is assumed 0.

EXAMPLE
   % pp_include "v/tb.pp";
   ...
   GenRst reset_n, 100

   Generates a 100 ns active low reset called 'reset_n'. 
   The code may translate to something like:

   reg reset_n;
   initial begin
      reset_n <= 0;
      #100;
      reset_n <= 1;
   end

SEE ALSO
   GenClk, GenRstMon

-------------------

NAME
   GenRstMon - generate a reset monitor for a testbench

SYNTAX
   % pp_include "v/tb.pp";
   ...
   GenRstMon reset_name [, active_value]

DESCRIPTION
   Generates code to report in the simulation log file when a reset
   signal is asserted or deasserted

   if active_value is ommited it is assumed 0.

EXAMPLE
   % pp_include "v/tb.pp";
   ...
   GenRstMon reset_n

   The code may translate to something like:

   always @(reset_n) begin
      if (reset_n == 0) begin
         $display($time, " Reset rest_n is ACTIVE");
      end
      else begin
         $display($time, " Reset rest_n is inactive");
      end
   end

SEE ALSO
   GenRst
