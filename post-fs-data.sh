#!/system/bin/sh
# Bootstrap APEX CA injection; runs early at boot before zygote.

MODDIR=${0%/*}
LOG_FILE="/data/local/tmp/trustanycert.log"
CERT_DIR="${MODDIR}/system/etc/security/cacerts"
TEMP_DIR="/data/local/tmp/trustanycert-apex-ca"

mkdir -p /data/local/tmp 2>/dev/null
echo "" > "$LOG_FILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "╔════════════════════════════════════════════════════╗"
log "║  TrustAnyCert v1.0                                 ║"
log "╚════════════════════════════════════════════════════╝"
log ""
log "Post-fs-data started"
log "Module: $MODDIR"

API=$(getprop ro.build.version.sdk)
ANDROID_VERSION=$(getprop ro.build.version.release)
log "Android: $ANDROID_VERSION (API $API)"

if [ "$KSU" = "true" ]; then
    log "Root: KernelSU/SukiSU (v$KSU_VER_CODE)"
elif [ "$APATCH" = "true" ]; then
    log "Root: APatch (v$APATCH_VER_CODE)"
else
    log "Root: Magisk/Other"
fi

mkdir -p "$CERT_DIR"
CERT_COUNT=$(find "$CERT_DIR" -maxdepth 1 -type f -name "*.[0-9]*" 2>/dev/null | wc -l)
CERT_COUNT=$(echo "$CERT_COUNT" | tr -d ' ')

if [ "$CERT_COUNT" = "0" ] || [ -z "$CERT_COUNT" ]; then
    log "No certificates uploaded yet. Use the WebUI to add one."
    log "Cert dir: $CERT_DIR"
    exit 0
fi

log "Found $CERT_COUNT certificate(s):"
find "$CERT_DIR" -maxdepth 1 -type f -name "*.[0-9]*" 2>/dev/null | while read c; do
    log "  - $(basename "$c")"
done

if [ "$API" -lt 34 ]; then
    log "Android < 14: Using Magic Mount"
    log "Done!"
    exit 0
fi

log ""
log "=== Android 14+ APEX Injection ==="

APEX_CACERTS="/apex/com.android.conscrypt/cacerts"

if [ ! -d "$APEX_CACERTS" ]; then
    log "ERROR: APEX cacerts not found"
    exit 1
fi

log "Preparing tmpfs..."
umount "$TEMP_DIR" 2>/dev/null
rm -rf "$TEMP_DIR" 2>/dev/null
mkdir -p "$TEMP_DIR"

if ! mount -t tmpfs tmpfs "$TEMP_DIR"; then
    log "ERROR: Failed to mount tmpfs"
    exit 1
fi

log "Copying system certificates..."
cp -a "$APEX_CACERTS"/* "$TEMP_DIR/" 2>/dev/null
ORIG_COUNT=$(ls -1 "$TEMP_DIR"/*.[0-9]* 2>/dev/null | wc -l)
log "System certs: $ORIG_COUNT"

for CERT_FILE in "$CERT_DIR"/*.[0-9]*; do
    [ -f "$CERT_FILE" ] || continue
    CERT_NAME=$(basename "$CERT_FILE")
    log "Adding: $CERT_NAME"
    cp -f "$CERT_FILE" "$TEMP_DIR/$CERT_NAME"
done

chown -R 0:0 "$TEMP_DIR"
chmod 755 "$TEMP_DIR"
chmod 644 "$TEMP_DIR"/*

APEX_CONTEXT=$(ls -Zd "$APEX_CACERTS" 2>/dev/null | awk '{print $1}')
if [ -n "$APEX_CONTEXT" ] && [ "$APEX_CONTEXT" != "?" ]; then
    chcon -R "$APEX_CONTEXT" "$TEMP_DIR" 2>/dev/null
    log "SELinux context: $APEX_CONTEXT"
fi

TOTAL_COUNT=$(ls -1 "$TEMP_DIR"/*.[0-9]* 2>/dev/null | wc -l)
log "Total certs: $TOTAL_COUNT"

log ""
log "Mounting to APEX..."

mount --bind "$TEMP_DIR" "$APEX_CACERTS" && log "✓ Global mount"
nsenter --mount=/proc/1/ns/mnt -- mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null && log "✓ Init (PID 1)"

# Zygote namespaces are what every app process inherits from
for zygote in zygote zygote64; do
    PID=$(pidof "$zygote" 2>/dev/null)
    if [ -n "$PID" ]; then
        nsenter --mount=/proc/$PID/ns/mnt -- mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null && log "✓ $zygote (PID $PID)"
    fi
done

# Per-app namespaces are injected by service.sh post-boot; keep this script lightweight.
log "Deferred per-app namespace injection to service.sh"

log ""
MISSING=0
for CERT_FILE in "$CERT_DIR"/*.[0-9]*; do
    [ -f "$CERT_FILE" ] || continue
    CERT_NAME=$(basename "$CERT_FILE")
    if [ -f "$APEX_CACERTS/$CERT_NAME" ]; then
        log "✓ $CERT_NAME visible in APEX"
    else
        log "✗ $CERT_NAME not visible (namespace isolation, service.sh will retry)"
        MISSING=$((MISSING+1))
    fi
done
[ "$MISSING" -eq 0 ] && log "✓ SUCCESS: all certificates visible in APEX"

log ""
log "Post-fs-data completed"
log "══════════════════════════════════════════════════════"