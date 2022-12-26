// See http://www.cse.nd.edu/courses/cse20221/www/handouts/L17_FSM%20Design%20Example%20with%20Verilog.pdf

module motor(
    input clk, activate, up_limit, dn_limit, rst_n,
    output motor_up, motor_dn
);

@MacroDef(waitfor, expr);
      `tick; while (! (${expr}) ) `tick;
@MacroEnd;

SmBegin
   reg motor_up = 0;
   reg motor_dn = 0;
SmForever
   if (up_limit) begin
      waitfor(activate);
      motor_dn = 1;
      waitfor(dn_limit);
      motor_dn = 0;
   end
   else begin
      waitfor(activate);
      motor_up = 1;
      waitfor(up_limit);
      motor_up = 0;
   end
SmEnd

endmodule
