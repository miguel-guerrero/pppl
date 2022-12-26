ALGOFSM ?= ../../../algofsm/algo_fsm.py
ALGOFSM_OPT ?= -sd 1
PP ?= ../../pp.pl
PP_OPTS ?= -q
CLEAN_MORE ?=
COMP=iverilog -o ./sim.x -g2005-sv
SIM=vvp ./sim.x

%.v : pp.%.vb $(PP)
	$(PP) $(PP_OPTS) -I ../.. -ips dbg.pl $< -o - | $(ALGOFSM) $(ALGOFSM_OPT) -o $@

%.c : pp.%.c $(PP)
	$(PP) $(PP_OPTS) -I ../.. $< -ips dbg.pl

%.run.log : %_tb.v %.v
	$(COMP) $*_tb.v $*.v
	$(SIM) | tee $*.run.log

clean: $(CLEAN_MORE)
	rm -f $(TARGETS) *~ pp*.pl dbg.pl *.run.log sim.x *.vcd *.v

.PHONY: clean

.PRECIOUS: %.vb %.v
