#TARGETS=arb.v read_with_ws.v motor.v
TARGETS=arb.v arb.run.log
CLEAN_MORE=clean_more
#ALGOFSM_OPT=-behav

test: $(TARGETS)

include ../rules.mk

clean_more:
	rm -f *.v *.va arb.vb arb_tb.vb dump.vcd dump.v file_list.i
