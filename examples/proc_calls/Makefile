#TARGETS=arb.v read_with_ws.v motor.v
TARGETS=sample.v sample.run.log
CLEAN_MORE=clean_more
#ALGOFSM_OPT=-behav

test: $(TARGETS)

include ../rules.mk

clean_more:
	rm -f sample.vb sample_tb.vb run.log dump.vcd dump.v file_list.i
