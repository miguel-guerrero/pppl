

module fsm_cc1_1(
    input  go, ws, clk, rst_n,
    output rd, ds,
);

SmBegin
   reg rd = 0;
   reg ds = 0;
SmForever
   if (go) begin
      rd = 1'b1;
      `tick;
      `tick;
      while (!ws) begin
          ds = 1'b1;
          `tick;
          `tick;
      end
      rd = 1'b0;
      ds = 1'b0;
   end
SmEnd

endmodule
