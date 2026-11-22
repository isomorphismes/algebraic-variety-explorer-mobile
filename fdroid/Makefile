# Make is the fixed bootstrap interface before Grease exists. The maintained
# provisioning implementation continues in source-tools.grease once the pinned
# Cat Food source bootstrap has produced Grease through the owned ICK compiler.
REPOSITORY := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
OUTPUT ?= $(REPOSITORY)/.build/fdroid-tools
BUILD_JOBS ?= 2
CHEZ_ARCHIVE ?= $(REPOSITORY)/.build/fdroid-inputs/chez.tar.gz
CHEZ_SOURCE ?= $(REPOSITORY)/.build/fdroid-inputs/chez-source
GREASE_CHECKOUT := $(OUTPUT)/runtime/grease
GREASE := $(OUTPUT)/runtime/.build/grease/bin/grease
GREASE_REVISION := f19c94c6df18cddbdc1e81463e5bd689533e3c13
RELEASE_EVIDENCE := $(REPOSITORY)/.build/reproducible-source
RELEASE_VERSION := $(shell awk -F '\t' '$$1 == "VERSION_NAME" { print $$2 }' "$(REPOSITORY)/build-values.tsv")
RELEASE_APK := Algebraic-Variety-Explorer-$(RELEASE_VERSION)-unsigned.apk

.PHONY: all release prepare-chez-source chez-source-manifests verify-original-chez-source verify-chez-source preflight host-ick prepare-grease-source grease source-tools
all: source-tools

release: source-tools
	PATH="$(dir $(GREASE)):$$PATH" "$(GREASE)" "$(REPOSITORY)/fdroid/reproducible.grease" "$(REPOSITORY)" "$(FRONTEND)" "$(BACKEND)" "$(SDK)" "$(OUTPUT)" "$(RELEASE_EVIDENCE)" "$$(git -C "$(REPOSITORY)" rev-parse HEAD)"
	cp "$(RELEASE_EVIDENCE)/$(RELEASE_APK)" "$(REPOSITORY)/.build/$(RELEASE_APK)"

# Pre-scanner preparation only: verify and unpack the unchanged upstream source
# distribution, record its content profile, and remove the consumed archive.
# No executable is built before F-Droid's source scan.
prepare-chez-source:
	printf '%s  %s\n' 2e74952db7bc177f0c3602e2217a341ba677d733eec4cd7726418c3a4e1ef308 "$(CHEZ_ARCHIVE)" | sha256sum -c -
	test ! -e "$(CHEZ_SOURCE)"
	mkdir -p "$(CHEZ_SOURCE)"
	tar --no-same-owner --strip-components=1 -xzf "$(CHEZ_ARCHIVE)" -C "$(CHEZ_SOURCE)"
	$(MAKE) -f "$(REPOSITORY)/fdroid/Makefile" verify-original-chez-source CHEZ_SOURCE="$(CHEZ_SOURCE)"
	cp "$(CHEZ_SOURCE).files.sha256" "$(CHEZ_SOURCE).original-files.sha256"
	cp "$(CHEZ_SOURCE).entries.txt" "$(CHEZ_SOURCE).original-entries.txt"
	printf '%s  %s\n' 3fec2ac0604510a1327930b4450f2b48080d648a1d593d7b3b2072394275adc4 "$(CHEZ_SOURCE)/lz4/tests/goldenSamples/skip.bin" | sha256sum -c -
	rm -- "$(CHEZ_SOURCE)/lz4/tests/goldenSamples/skip.bin"
	$(MAKE) -f "$(REPOSITORY)/fdroid/Makefile" verify-chez-source CHEZ_SOURCE="$(CHEZ_SOURCE)"
	printf 'version\t10.4.1\narchive_SHA256\t2e74952db7bc177f0c3602e2217a341ba677d733eec4cd7726418c3a4e1ef308\noriginal_file_count\t1167\noriginal_manifest_SHA256\tedb1c9560113d60a4e2ace1e74defd67e71005414379b2b7c27eb8d976cf55c6\noriginal_entries_SHA256\tc81fed0074a5a2a1837df5ec3b4a35e78cb92178e0a27081b984762357455364\npruned_fixture\tlz4/tests/goldenSamples/skip.bin\npruned_fixture_SHA256\t3fec2ac0604510a1327930b4450f2b48080d648a1d593d7b3b2072394275adc4\nprepared_file_count\t1166\nsource_manifest_SHA256\t2293add776428288d30d1f90d90ab6b411cf93ed1ccf2ae707f6d7821a566f97\nsource_entries_SHA256\tc5694ec102f4b86a69fe10414e27e2e988f5d37a7f2f62b88748e14ee2110054\n' > "$(CHEZ_SOURCE).provenance.tsv"
	rm -- "$(CHEZ_ARCHIVE)"

chez-source-manifests:
	test -x "$(CHEZ_SOURCE)/configure"
	test -s "$(CHEZ_SOURCE)/BUILDING"
	test -z "$$(find "$(CHEZ_SOURCE)" ! -type d ! -type f -print -quit)"
	cd "$(CHEZ_SOURCE)" && LC_ALL=C find . -printf '%y %p\n' | LC_ALL=C sort > "$(CHEZ_SOURCE).entries.txt"
	cd "$(CHEZ_SOURCE)" && LC_ALL=C find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > "$(CHEZ_SOURCE).files.sha256"

verify-original-chez-source: chez-source-manifests
	printf '%s  %s\n' c81fed0074a5a2a1837df5ec3b4a35e78cb92178e0a27081b984762357455364 "$(CHEZ_SOURCE).entries.txt" | sha256sum -c -
	printf '%s  %s\n' edb1c9560113d60a4e2ace1e74defd67e71005414379b2b7c27eb8d976cf55c6 "$(CHEZ_SOURCE).files.sha256" | sha256sum -c -
	test "$$(wc -l < "$(CHEZ_SOURCE).files.sha256")" = 1167

# Only one unused upstream LZ4 command-line test fixture is pruned. Chez's
# production build uses lz4/lib; no application or compiler source is removed.
verify-chez-source: chez-source-manifests
	printf '%s  %s\n' c81fed0074a5a2a1837df5ec3b4a35e78cb92178e0a27081b984762357455364 "$(CHEZ_SOURCE).original-entries.txt" | sha256sum -c -
	printf '%s  %s\n' edb1c9560113d60a4e2ace1e74defd67e71005414379b2b7c27eb8d976cf55c6 "$(CHEZ_SOURCE).original-files.sha256" | sha256sum -c -
	printf '%s  %s\n' c5694ec102f4b86a69fe10414e27e2e988f5d37a7f2f62b88748e14ee2110054 "$(CHEZ_SOURCE).entries.txt" | sha256sum -c -
	printf '%s  %s\n' 2293add776428288d30d1f90d90ab6b411cf93ed1ccf2ae707f6d7821a566f97 "$(CHEZ_SOURCE).files.sha256" | sha256sum -c -
	test "$$(wc -l < "$(CHEZ_SOURCE).files.sha256")" = 1166

preflight:
	test "$$(uname -s)" = Linux
	test "$$(uname -m)" = x86_64
	test "$$(git -C "$(AI_CI)" rev-parse HEAD)" = 32cb45b3a3a257aeb07881c75f3b846495cfb2c9
	test "$$(git -C "$(HOST_ICK)" rev-parse HEAD)" = fbe86e23d55cfec2000c08e61deea2a407fd7175
	test "$$(git -C "$(GREASE_SOURCE)" rev-parse HEAD)" = "$(GREASE_REVISION)"
	test "$$(git -C "$(CATFOOD)" rev-parse HEAD)" = 609a9628d5a52860f956bf62e0914a0cd03292ae
	test -d /usr/lib/gcc/x86_64-linux-gnu/13
	dpkg-query -W libc6 libgcc-13-dev

host-ick: preflight
	$(MAKE) -f "$(AI_CI)/ick-host/Makefile" all qualify ICK_SOURCE="$(HOST_ICK)" ICK_BUILD="$(OUTPUT)/host-build" ICK_STAGE="$(OUTPUT)/host-stage" BUILD_JOBS="$(BUILD_JOBS)"

# Use fresh local source checkouts so the compatibility patch and Grease's
# generated files stay outside F-Droid's scanned srclib.
prepare-grease-source:
	test "$$(git -C "$(GREASE_SOURCE)" rev-parse HEAD)" = "$(GREASE_REVISION)"
	test "$$(git -C "$(GREASE_SOURCE)/source" rev-parse HEAD)" = "$$(git -C "$(GREASE_SOURCE)" rev-parse HEAD:source)"
	test ! -e "$(GREASE_CHECKOUT)"
	git clone --shared --no-checkout "$(GREASE_SOURCE)" "$(GREASE_CHECKOUT)"
	git -C "$(GREASE_CHECKOUT)" checkout --detach "$(GREASE_REVISION)"
	git clone --shared --no-checkout "$(GREASE_SOURCE)/source" "$(GREASE_CHECKOUT)/source"
	git -C "$(GREASE_CHECKOUT)/source" checkout --detach "$$(git -C "$(GREASE_CHECKOUT)" rev-parse HEAD:source)"
	git -C "$(GREASE_CHECKOUT)/source" apply "$(REPOSITORY)/fdroid/patches/python2-private-sinpi.patch"

grease: host-ick prepare-grease-source
	CATFOOD_ROOT="$(OUTPUT)/runtime" CATFOOD_JOBS="$(BUILD_JOBS)" CC="$(OUTPUT)/host-stage/bin/gcc -fno-link-libatomic -std=gnu11" sh "$(CATFOOD)/build-tools.sh"

source-tools: grease
	"$(GREASE)" "$(REPOSITORY)/fdroid/source-tools.grease" "$(REPOSITORY)" "$(FRONTEND)" "$(BACKEND)" "$(CROSS_ICK)" "$(OUTPUT)/host-stage/bin/gcc" "$(SDK)" "$(OUTPUT)" "$(CHEZ_SOURCE)" "$(BAKSMALI)" "$(SMALI)"
