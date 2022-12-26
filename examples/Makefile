
DIRS=motor proc_calls arb read_with_ws c_cover c_unwrap

test:
	for i in $(DIRS); do echo "=== $$i ===" ; make -C $$i test || exit 1; done
	@echo "All tests runned passed"

clean:
	for i in $(DIRS); do echo "=== $$i ===" ; make -C $$i clean || exit 1; done

