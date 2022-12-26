Library contents:

v/pp_lib - this library is automatically included for verilog files
--------------------------------------------------------------------------


--------------------------------------------------------------------------
sign_extend - sign extends a signal from m to n bits
--------------------------------------------------------------------------
SYNTAX
   sign_extend(signal_name, output_width, input_width[, input_lsb])

DESCRIPTION
   Given a signal previously declared as 

   [reg|wire] [input_widht-1+input_lsb:input_lsb] signal_name;

   it would generate an expresion that is equivalent to sign extend it to 'output_width' bits

   'input_lsb' is assumed 0 if not provided

EXAMPLE

   The following

      reg [15:0] a;
      reg [23:0] a_wider;
      ...

      a_wider <= $(( sign_extend a, 24, 16 ));

   May translate to something like:

      a_wider <= { {8 {a[15]}}, a[15:0] };

   You can also do for same results:

      % $new_a = &sign_extend(a,24,16);
      a_wider <= ${new_a}

SEE ALSO
   logic_extend

--------------------------------------------------------------------------
logic_extend - zero extends a signal from m to n bits
--------------------------------------------------------------------------

SYNTAX
   logic_extend(signal_name, output_width, input_width[, input_lsb])

DESCRIPTION
   Given a signal previously declared as 

   [reg|wire] [input_widht-1+input_lsb:input_lsb] signal_name;

   it would generate an expresion that is equivalent to logic extend it to 'output_width' bits

   'input_lsb' is assumed 0 if not provided

EXAMPLE

   The following

      reg [15:0] a;
      reg [23:0] a_wider;
      ...

      a_wider <= $(( logic_extend a, 24, 16 ));

   May translate to something like:

      a_wider <= {8'b0, a[15:0] };

   You can also do for same results:

      % $new_a = &logic_extend(a,24,16);
      a_wider <= ${new_a}

SEE ALSO
   sign_extend

--------------------------------------------------------------------------
bit select
--------------------------------------------------------------------------





--------------------------------------------------------------------------
Repeat - transform a repeat loop into a while loop
--------------------------------------------------------------------------
SYNTAX
   Repeat (var_name, number_iter)
   ...
   End | RepeatEnd

DESCRIPTION
   Generates a while loop that ensures a given number of iterations

EXAMPLE

   Repeat (i, 5)
      addr <= i;
      req <= 1;
      `tick;
      while (~gnt) `tick;
   End

   Translates into:

   i=0;
   while (i<5) begin

      addr <= i;
      req <= 1;
      `tick;
      while (~gnt) `tick;

      i=i+1;
   end

SEE ALSO
   Switch/SwitchEnd

--------------------------------------------------------------------------
Switch - multi condition block
--------------------------------------------------------------------------
SYNTAX
   Switch(var) 
      Case(value0)
      ...

     [Case(valuek)
      ...]

     [Default
      ...]
   End | SwitchEnd

DESCRIPTION
   generates multilevel conditional that translates into cascaded
   if/else if/else statements. This allows to insert clock cycles
   anywhere and still be supported by AlgoFSM

EXAMPLE

   Switch(a)
      ... Always exec ...
      Case(1)
         x <= 5;
      Case(2)
         x <= 7;
      Case(3)
         x <= 9;
      Default
         x <= 0;
   End

   Translates into:
      ... Always exec ...
      if (a==1) begin
          x<=5;
      end else if (a==2) begin
         x <= 7;
      end else if (a==3) begin
         x <= 9;
      end else begin
         x <= 0;
      end

SEE ALSO
   Repeat

--------------------------------------------------------------------------
TaskDef/TaskDefEnd - Task definition

Task - Task invokation
--------------------------------------------------------------------------

SYNTAX

   Task definition:

      TaskDef name[, formal_arg_list] | TaskDef (name[,formal_arg_list])
      ...
      TaskDefEnd

      formal_arg_list = formal_arg [formal_arg_list]
      formal_arg := [in] var_name | out var_name | io var_name

   Task invokation:

      Task name[, actual_arg_list] | Task (name[, actual_arg_list])

      actual_arg_list := expression [actual_arg_list]

      Where expression is restricted to be a variable name for 'io' or 'out' type of arguments

DESCRIPTION
   Define a Task that can be called later on from behavioral code (to be processed by AlgoFSM)
   The caller invokes a call to the task by invoking Task(name[,actual_arg_list])
   The net result is that the code withing TaskDef/TaskDefEnd is **inlined** in the code by 
   substituting formal parameters with actual ones (it behaves as a multi line macro)

   TaskDef/TaskDefEnd can contain `tick events, i.e. it can be a time consuming task

   If two Tasks are invoked consecutively in the code, they are executed fully sequentially

EXAMPLE

   TaskDef mul_add m, x, b, out res
      reg [31:0] t;
      t = m * x;
      `tick;
      res = t + b;
      `tick;
   TaskDefEnd

   Example of call from a behavioral block (within AlgoFSM body)

       // computes ((20x+1)*x + 2)*x + 3 = 20 x^3 + x^2 + 2x + 3;
       res = 0;
       Task mul_add 20, x, 1, res;
       Task mul_add res, x, 2, res;
       Task mul_add res, x, 3, res;

SEE ALSO
   ProcDef/ProcDefEnd/ProcStart/ProcJoin


--------------------------------------------------------------------------
ProcDef/ProcDefEnd - Process definition

ProcStart - Process invokation

ProcJoin - Wait for process completion
--------------------------------------------------------------------------
SYNTAX
   Process definition:

      ProcDef name[, formal_arg_list] | ProcDef (name[,formal_arg_list])
      ... time consuming code (`tick allowed)
      ProcDefEnd

      formal_arg_list = formal_arg [formal_arg_list]
      formal_arg := [in] var_name | out var_name | io var_name

   Process invokation:

      ProcStart name[, actual_arg_list] | Task (name[, actual_arg_list])

      actual_arg_list := expression [actual_arg_list]

      Where expression is restricted to be a variable name for 'io' or 'out' type of arguments

   Wait for process completion:

      ProcJoin(proc_list)

      proc_list := proc_name [ proc_list]

      When multiple processes are provided, the call waits for all of them to complete


DESCRIPTION
   This set of constructs allows you to define processes that can be invoked in parallel
   The generated code produces a AlgoFSM construnct (which will become a state machine) that
   implements a go/done protocol with the caller. The process waits for a 'go' then copies
   actual parameters into its formal parameters, executes its body, copies resulta to the
   caller out|io actual parameters and gives a 'done' to the caller

   The caller can launch several of these processes in parallel and wait for all of them
   to complete before compliting by calling ProcJoin on the list of processes to wait for
   ProcJoin waits for all 'done' signals to be asserted from the callees and the deasserts
   the respective 'go' ones to complete the full cycle

EXAMPLE

   Example of Proc definitions:

      ProcDef(min, in [15:0] x, in[15:0] y, in [15:0] z, out [15:0] res)
         res = x;
         `tick;
         if (y < res) res = y;
         `tick;
         if (z < res) res = z;
      ProcDefEnd

      ProcDef(max, in [15:0] x, in[15:0] y, in [15:0] z, out [15:0] res)
         if (x > y) res = x;
         else       res = y;
         `tick;
         if (z > res) res = z;
      ProcDefEnd

   Example of Proc invokation and wait for completion:

      SmBegin
         reg [15:0] min0;
         reg [15:0] max0;
         reg [3:0] cnt = 4'b0;
      SmForever
         ProcStart(min, 11, 21, 31, min0);
         ProcStart(max, 11, 21, 31, max0);
         // do something else here
         // ...
         // Wait for min/max values to be ready
         ProcJoin(min, max);
         `tick;
         $display($time, " min=%d max=%d cnt=%d", min0, max0, cnt);
      SmEnd

SEE ALSO
   TaskDef/TaskDefEnd

-------------------
