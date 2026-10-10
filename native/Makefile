ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
ICK_CC ?= ick
ICK_LINK_FLAGS ?= -fno-link-libatomic
BUILD ?= $(ROOT)/.build
SANITIZE ?= 0
CFLAGS := -std=c17 -Wall -Wextra -Werror -pedantic -fno-fast-math -ffp-contract=off
ifeq ($(SANITIZE),1)
CFLAGS += -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer
else
CFLAGS += -O2
endif

.PHONY: test
test:
	mkdir -p "$(BUILD)"
	"$(ICK_CC)" $(CFLAGS) $(ICK_LINK_FLAGS) $(ICK_SUPPORT_FLAGS) \
	  "$(ROOT)/native/surfer_raytracer.c" "$(ROOT)/native/surfer_raytracer_test.c" \
	  -lm -o "$(BUILD)/surfer-raytracer-test"
	"$(BUILD)/surfer-raytracer-test"
	@set +e; "$(BUILD)/surfer-raytracer-test" --negative-near-nan \
	  >"$(BUILD)/surfer-raytracer-negative-nan.log" 2>&1; status=$?; \
	  if [ "$status" -ne 1 ] || \
	     ! grep -Fq 'FAIL: negative-control NaN:' "$(BUILD)/surfer-raytracer-negative-nan.log"; then \
	    cat "$(BUILD)/surfer-raytracer-negative-nan.log" >&2; \
	    printf 'FAIL: native floating-point negative control did not reject NaN (status=%s)\n' "$status" >&2; \
	    exit 1; \
	  fi; \
	  printf 'SURFER native NaN negative control: PASS\n'
