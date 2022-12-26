//====================================================
// This is FSM generation demo using AlgoFSM
// File Name   : pp.arb.vb
//=====================================================
module arb (
   input  clk, rst_n, req_0, req_1,
   output gnt_0, gnt_1
);

@pp_include "autoloads/v/utils.pp"

SmBegin
   reg gnt_0 = 0;
   reg gnt_1 = 0;
SmForever
    if (req_0 == 1'b1) begin
       gnt_0 = 1;
       waitfor(req_0 == 1'b0);
       gnt_0 = 0;
    end else if (req_1 == 1'b1) begin
       gnt_1 = 1;
       waitfor(req_1 == 1'b0);
       gnt_1 = 0;
    end
SmEnd
 
endmodule
