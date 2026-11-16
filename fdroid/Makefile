# Make is the fixed bootstrap interface before Grease exists. The maintained
# provisioning implementation continues in source-tools.grease once the pinned
# Cat Food source bootstrap has produced Grease through the owned ICK compiler.
REPOSITORY := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
OUTPUT ?= $(REPOSITORY)/.build/fdroid-tools
BUILD_JOBS ?= 2

.PHONY: all preflight host-ick grease source-tools
all: source-tools

preflight:
	test "$$(uname -s)" = Linux
	test "$$(uname -m)" = x86_64
	test "$$(git -C "$(AI_CI)" rev-parse HEAD)" = 32cb45b3a3a257aeb07881c75f3b846495cfb2c9
	test "$$(git -C "$(HOST_ICK)" rev-parse HEAD)" = fbe86e23d55cfec2000c08e61deea2a407fd7175
	test "$$(git -C "$(GREASE_SOURCE)" rev-parse HEAD)" = f19c94c6df18cddbdc1e81463e5bd689533e3c13
	test "$$(git -C "$(CATFOOD)" rev-parse HEAD)" = 609a9628d5a52860f956bf62e0914a0cd03292ae
	test -d /usr/lib/gcc/x86_64-linux-gnu/13
	dpkg-query -W libc6 libgcc-13-dev

host-ick: preflight
	$(MAKE) -f "$(AI_CI)/ick-host/Makefile" all qualify ICK_SOURCE="$(HOST_ICK)" ICK_BUILD="$(OUTPUT)/host-build" ICK_STAGE="$(OUTPUT)/host-stage" BUILD_JOBS="$(BUILD_JOBS)"

grease: host-ick
	mkdir -p "$(OUTPUT)/runtime"
	test ! -e "$(OUTPUT)/runtime/grease"
	ln -s "$(GREASE_SOURCE)" "$(OUTPUT)/runtime/grease"
	CATFOOD_ROOT="$(OUTPUT)/runtime" CATFOOD_JOBS="$(BUILD_JOBS)" CC="$(OUTPUT)/host-stage/bin/gcc -fno-link-libatomic -std=gnu11" sh "$(CATFOOD)/build-tools.sh"

source-tools: grease
	"$(OUTPUT)/runtime/.build/grease/bin/grease" "$(REPOSITORY)/fdroid/source-tools.grease" "$(REPOSITORY)" "$(FRONTEND)" "$(BACKEND)" "$(CROSS_ICK)" "$(OUTPUT)/host-stage/bin/gcc" "$(SDK)" "$(OUTPUT)" "$(CHEZ_ARCHIVE)" "$(BAKSMALI)" "$(SMALI)"
