
Library contents:

v/utils
--------------------------------------------------------------------------

NAME
   waitfor - wait 1 or more clock cycles until a condition is met

SYNTAX
   % pp_include "v/utils";
   ...
   waitfor condition

   OR

   % pp_include "v/utils";
   ...
   waitfor (condition);

DESCRIPTION
   Intended to be used in behavioral code to be procesed later on by AlgoFSM
   or in testbenches, waits for 'condition' to be true before continuing

NOTE
   It generates code using the special macro `tick
   This macro is defined by AlgoFSM based on your clock and reset definitions
   For example AlgoFSM may have defined it as:
      `define tick @(posedge clk or negedge reset_n)
   
EXAMPLE
   % pp_include "v/utils";
   ...
   req <= 1;
   waitfor (ack == 1);

   The code may translate to something like:

   req <= 1;
   `tick; while (! (ack == 1)) `tick;

SEE ALSO
   AlgoFSM documentation

-------------------
