#!/usr/bin/env bash
# Build TrustAnyCert module zip.
# Usage:
#   ./build.sh                # picks version from module.prop
#   ./build.sh v1.1           # overrides version
#   OUT_DIR=out ./build.sh    # overrides output directory
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

VERSION="${1:-$(awk -F= '/^version=/ { print $2 }' module.prop | tr -d '[:space:]')}"
if [ -z "$VERSION" ]; then
    echo "ERROR: could not determine version (pass as arg or set in module.prop)" >&2
    exit 1
fi

OUT_DIR="${OUT_DIR:-dist}"
NAME="TrustAnyCert-${VERSION}"
OUT="${OUT_DIR}/${NAME}.zip"

mkdir -p "$OUT_DIR"
rm -f "$OUT"

echo "Packaging $NAME ..."

# Files / dirs that must be shipped in the flashable zip
PAYLOAD=(
    module.prop
    customize.sh
    post-fs-data.sh
    service.sh
    action.sh
    uninstall.sh
    update.json
    META-INF
    system
    webroot
    LICENSE
)

# Sanity: fail early if anything is missing
for p in "${PAYLOAD[@]}"; do
    if [ ! -e "$p" ]; then
        echo "ERROR: required path missing: $p" >&2
        exit 1
    fi
done

zip -r9 -q "$OUT" "${PAYLOAD[@]}" \
    -x '*.DS_Store' '**/.DS_Store' \
       '*.gitkeep' '**/.gitkeep' \
       '*/.gitignore' \
       'webroot/*.map'

SIZE="$(du -h "$OUT" | cut -f1)"
echo "OK  $OUT  ($SIZE)"
