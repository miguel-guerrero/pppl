TARGETS=arb_rr.v arb_rr.run.log
CLEAN_MORE=clean_more
#ALGOFSM_OPT=-behav

test: $(TARGETS)

include ../rules.mk

syn: arb_rr.v
	yosys -p "read_verilog -sv $<; proc; opt; write_verilog syn.$<"

clean_more:
	rm -f *.v arb*.vb dump.vcd
