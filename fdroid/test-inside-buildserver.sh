#!/usr/bin/env bash
set -euo pipefail

readonly APP_ID=org.algebraicvarietyexplorer
readonly REPO_ROOT=/workspace/algebraic-variety-explorer-mobile
readonly FDROIDDATA_REVISION=4498e27635a1c3b737510342c1f2355c25ce0211
readonly FDROIDSERVER_REVISION=6af4c4216e43d0fcb29e33919cd0fe8fef7e7400
readonly SOURCE_REPO="${SOURCE_REPO:-https://github.com/isomorphisms/algebraic-variety-explorer-mobile.git}"
readonly SOURCE_REVISION="${SOURCE_REVISION:?SOURCE_REVISION is required}"
source "$REPO_ROOT/ci/release-values.sh"

readonly BUILD_ID="$APP_ID:$AVE_VERSION_CODE"
readonly WORK_ROOT="$(mktemp -d /tmp/ave-fdroiddata.XXXXXX)"
readonly DATA="$WORK_ROOT/fdroiddata"
readonly SERVER="$WORK_ROOT/fdroidserver"
readonly ORIGINAL_METADATA="$WORK_ROOT/original-metadata.yml"

chmod 0755 "$WORK_ROOT"
cleanup() {
    if [[ -L /home/vagrant/fdroiddata ]]; then
        rm /home/vagrant/fdroiddata
    fi
    rm -f "/home/vagrant/metadata/$APP_ID.yml"
    rm -rf "/home/vagrant/build/$APP_ID"
    rm -rf "$WORK_ROOT"
}
trap cleanup EXIT

git clone --filter=blob:none https://gitlab.com/fdroid/fdroiddata.git "$DATA"
git -C "$DATA" checkout --detach "$FDROIDDATA_REVISION"
git clone --filter=blob:none https://gitlab.com/fdroid/fdroidserver.git "$SERVER"
git -C "$SERVER" checkout --detach "$FDROIDSERVER_REVISION"

cp "$REPO_ROOT/org.algebraicvarietyexplorer.yml.template" "$DATA/metadata/$APP_ID.yml"
sed -i "s|^Repo: .*|Repo: $SOURCE_REPO|" "$DATA/metadata/$APP_ID.yml"
sed -i \
    "/^  - versionName: $AVE_VERSION_NAME$/,/^    commit: / s|^    commit: .*|    commit: $SOURCE_REVISION|" \
    "$DATA/metadata/$APP_ID.yml"
cp "$DATA/metadata/$APP_ID.yml" "$ORIGINAL_METADATA"

export PATH="$SERVER:$PATH"
export PYTHONPATH="$SERVER:$SERVER/examples"
export PYTHONUNBUFFERED=true
export serverwebroot=/tmp
export ANDROID_HOME=/opt/android-sdk

cd "$DATA"
chmod 0600 config.yml
find config -type f -name '*.yml' -exec chmod 0600 {} +

apt-get update
apt-get install -y --no-install-recommends \
    jq \
    openjdk-21-jdk-headless \
    python3-markdown-it \
    python3-pip \
    sudo

fdroid lint "$APP_ID"
fdroid rewritemeta "$APP_ID"
cmp "$ORIGINAL_METADATA" "metadata/$APP_ID.yml"

python3 -m pip install --quiet --break-system-packages check-jsonschema
check-jsonschema --schemafile schemas/metadata.json "metadata/$APP_ID.yml"

cp "metadata/$APP_ID.yml" "$WORK_ROOT/before-redirect.yml"
tools/rewrite-git-redirects.py "$APP_ID"
cmp "$WORK_ROOT/before-redirect.yml" "metadata/$APP_ID.yml"

python3 tools/check-fastlane.py "$APP_ID" > "$WORK_ROOT/fastlane.json"
python3 - "$WORK_ROOT/fastlane.json" <<'PY'
import json
import sys

reports = json.load(open(sys.argv[1], encoding="utf-8"))
bad = [report for report in reports if report.get("severity") in {"critical", "major"}]
for report in reports:
    print(f"{report.get('severity')}: {report.get('description')}")
if bad:
    raise SystemExit("F-Droid Fastlane checks reported critical or major problems")
PY

update-alternatives --set java /usr/lib/jvm/java-21-openjdk-amd64/bin/java
sdkmanager "platform-tools" "build-tools;31.0.0"
if [[ -f /etc/profile.d/bsenv.sh ]]; then
    # shellcheck disable=SC1091
    source /etc/profile.d/bsenv.sh
fi
readonly HOME_VAGRANT="${home_vagrant:-/home/vagrant}"
test -d "$HOME_VAGRANT"
git -C "$HOME_VAGRANT/gradlew-fdroid" pull --ff-only

mkdir -p "$DATA/build" "$DATA/logs" "$DATA/tmp" "$DATA/unsigned"
mkdir -p "$HOME_VAGRANT/.android" "$HOME_VAGRANT/.gradle" "$HOME_VAGRANT/metadata"
rm -rf "$HOME_VAGRANT/build"
cp -R "$DATA/build" "$HOME_VAGRANT/build"
ln -sfn "$DATA/tmp" "$HOME_VAGRANT/tmp"
ln -sfn "$DATA/srclibs" "$HOME_VAGRANT/srclibs"
cp "metadata/$APP_ID.yml" "$HOME_VAGRANT/metadata/"
chown -R vagrant "$HOME_VAGRANT" "$DATA"

run_fdroid() {
    sudo --preserve-env --user vagrant env \
        PATH="$SERVER:$PATH" \
        PYTHONPATH="$SERVER:$SERVER/examples" \
        PYTHONUNBUFFERED=true \
        TERM="${TERM:-dumb}" \
        HOME="$HOME_VAGRANT" \
        fdroid "$@"
}

cd "$HOME_VAGRANT"
ln -s "$DATA" "$HOME_VAGRANT/fdroiddata"
run_fdroid fetchsrclibs "$BUILD_ID" --verbose
rm "$HOME_VAGRANT/fdroiddata"
(unset CI; run_fdroid build --verbose --test --refresh-scanner --on-server --no-tarball "$BUILD_ID")

readonly APK="$DATA/tmp/${APP_ID}_${AVE_VERSION_CODE}.apk"
test -s "$APK"
fdroid scanner --verbose --exit-code "$APK"
ANDROID_SDK_ROOT=/opt/android-sdk "$REPO_ROOT/ci/verify-apk.sh" unsigned "$APK"
androguard axml "$APK" -o "$WORK_ROOT/AndroidManifest.xml"
if grep -Eq 'android:debuggable="true"|android:testOnly="true"|android:usesCleartextTraffic="true"' \
    "$WORK_ROOT/AndroidManifest.xml"; then
    printf 'fdroiddata: APK manifest contains a forbidden release/debug attribute\n' >&2
    exit 1
fi
if unzip -Z1 "$APK" | grep -Eq '^lib/[^/]+/'; then
    printf 'fdroiddata: Java-only APK unexpectedly contains native libraries\n' >&2
    exit 1
fi
cd "$DATA"
tools/audit-gradle.py "$APP_ID"

cp "$APK" "/output/${APP_ID}_${AVE_VERSION_CODE}.apk"
sha256sum "/output/${APP_ID}_${AVE_VERSION_CODE}.apk" \
    > "/output/${APP_ID}_${AVE_VERSION_CODE}.apk.sha256"
printf 'fdroiddata: production-like build passed at %s / %s\n' \
    "$FDROIDDATA_REVISION" "$FDROIDSERVER_REVISION"
