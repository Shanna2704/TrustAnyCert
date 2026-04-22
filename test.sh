#!/usr/bin/env bash
# Static + smoke tests for TrustAnyCert.
# Runs in CI and locally (including inside the build Docker image).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

fail=0
pass=0

ok()   { pass=$((pass+1)); printf '  \033[32mok\033[0m   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }

echo "== Module structure =="
required_paths=(
    module.prop
    customize.sh
    post-fs-data.sh
    service.sh
    action.sh
    uninstall.sh
    update.json
    META-INF/com/google/android/update-binary
    META-INF/com/google/android/updater-script
    webroot/index.html
    webroot/cert.js
    system/etc/security/cacerts
)
for p in "${required_paths[@]}"; do
    if [ -e "$p" ]; then ok "$p"; else bad "$p missing"; fi
done

echo
echo "== Shell syntax (POSIX /system/bin/sh) =="
# Module scripts run on the Android busybox / toybox shell, so they must
# parse under a strict POSIX /bin/sh.
for f in customize.sh post-fs-data.sh service.sh action.sh uninstall.sh; do
    if sh -n "$f" 2>/dev/null; then ok "$f"; else bad "$f syntax error"; fi
done

echo
echo "== Shell syntax (bash wrappers) =="
for f in build.sh test.sh; do
    if bash -n "$f" 2>/dev/null; then ok "$f"; else bad "$f syntax error"; fi
done

echo
echo "== module.prop consistency =="
mp_id=$(awk -F= '/^id=/ {print $2}' module.prop | tr -d '[:space:]')
mp_version=$(awk -F= '/^version=/ {print $2}' module.prop | tr -d '[:space:]')
mp_name=$(awk -F= '/^name=/ {print $2}' module.prop | tr -d '[:space:]')
[ "$mp_id" = "trustanycert" ]    && ok "id=$mp_id"             || bad "id mismatch: $mp_id"
[ -n "$mp_version" ]             && ok "version=$mp_version"   || bad "version empty"
[ "$mp_name" = "TrustAnyCert" ]  && ok "name=$mp_name"         || bad "name mismatch: $mp_name"

echo
echo "== JavaScript =="
if command -v node >/dev/null 2>&1; then
    if node --check webroot/cert.js 2>/dev/null; then
        ok "webroot/cert.js parses"
    else
        bad "webroot/cert.js parse error"
    fi

    echo
    echo "== Smoke tests =="
    if node tests/smoke.js; then
        ok "tests/smoke.js"
    else
        bad "tests/smoke.js failed"
    fi
else
    echo "  skipped (node not installed)"
fi

echo
if [ "$fail" -gt 0 ]; then
    echo "FAILED: $fail / $((pass + fail))"
    exit 1
fi
echo "PASSED: $pass checks"
