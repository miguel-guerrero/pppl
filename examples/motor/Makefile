#TARGETS=arb.v read_with_ws.v motor.v
TARGETS=motor.v motor.run.log
CLEAN_MORE=clean_more
#ALGOFSM_OPT=-behav

test: $(TARGETS)

include ../rules.mk

clean_more:
	rm -f motor.vb motor_tb.vb motor_tb.v
