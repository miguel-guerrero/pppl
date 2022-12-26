
@pp_include "autoloads/v/tb.pp"
@pp_include "autoloads/v/utils.pp"

module motor_tb;

GenClk clk, 5;
GenRst rst_n, 100;

`define tick @(posedge clk)

wire motor_up, motor_dn;
reg activate, up_limit, dn_limit;

motor motor_0 (.*);

initial begin
   up_limit <= 1;
   wait(rst_n == 1);
   $display($time, " Reset deasserted");
   `tick;
   activate <= 1;
   $display($time, " wait for motor_dn");
   waitfor(motor_dn == 1);
   $display($time, " Got motor_dn==1");
   `tick;
   `tick;
   `tick;
   `tick;
   dn_limit <= 1;
   $display($time, " wait for ~motor_dn");
   waitfor(motor_dn == 0);
   $display($time, " Got motor_dn==0");
   `tick;
   $finish;
end


endmodule
