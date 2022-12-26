#TARGETS=arb.v read_with_ws.v motor.v
TARGETS=sample.c sample2.c sample3.c
CLEAN_MORE=clean_more

test: $(TARGETS)

include ../rules.mk

sample.c: ../../autoloads/c/pp_lib.pl

sample2.c: pp.sample2.c ../../autoloads/c/pp_lib.pl 
	$(PP) $(PP_OPTS) -I ../.. $< -ts '\/\/\s*pragma' -ips dbg.pl

sample3.c: pp.sample3.c ../../autoloads/c/pp_lib.pl 
	$(PP) $(PP_OPTS) -I ../.. $< -ts '\/\/\s*pragma' -ips dbg.pl

clean_more:


