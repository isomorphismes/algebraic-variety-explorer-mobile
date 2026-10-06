CC ?= cc
CFLAGS ?= -std=c17 -Wall -Wextra -Werror -pedantic -O2 -fno-fast-math -ffp-contract=off
LDLIBS ?= -lm

.PHONY: test clean

test: surfer-poly-test
	./surfer-poly-test

surfer-poly-test: surfer_poly.c surfer_poly.h surfer_poly_test.c
	$(CC) $(CFLAGS) surfer_poly.c surfer_poly_test.c $(LDLIBS) -o $@

clean:
	rm -f surfer-poly-test
