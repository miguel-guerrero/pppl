 //====================================================
 // This is FSM generation demo using AlgoFSM
 // File Name : pp.arb_rr.vb
 //=====================================================
module arb_rr #(
    parameter LOG2_N = 2,
    parameter N = 1 << LOG2_N,
    parameter MASK = N - 1
) (
    input  clk, rst_n,
    input  [N-1:0] reqs,
    output reg [N-1:0] gnts
);

@pp_include(autoloads/v/utils.pp)

reg [LOG2_N-1: 0] gnt;

always_comb begin : calc_gnt
    integer i;
    reg [N-1: 0] j;
    gnt = 0;
    for (i=0; i < N; i=i+1) begin
        j = (lowest_pri + i) & MASK;
        if (reqs[j] == 1'b1) begin
            gnt = j;
        end
    end
end

SmBegin
    reg [LOG2_N-1:0] lowest_pri = 0;
SmForever
    if (|reqs) begin
        gnts = 1 << gnt;
        lowest_pri = gnt;
        waitfor(reqs == 0);
    end else begin
        gnts = 0;
    end
SmEnd
 
endmodule
