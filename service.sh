#!/system/bin/sh
# Post-boot APEX re-injection; also invoked by WebUI with FAST=1 to refresh
# the trust store after a cert add/delete without waiting for reboot.

MODDIR=${0%/*}
LOG_FILE="/data/local/tmp/trustanycert.log"
CERT_DIR="${MODDIR}/system/etc/security/cacerts"
TEMP_DIR="/data/local/tmp/trustanycert-apex-ca"
APEX_CACERTS="/apex/com.android.conscrypt/cacerts"
FAST_MODE="${FAST:-0}"  # WebUI passes FAST=1 to skip the boot-wait loop

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [service] $1" >> "$LOG_FILE"
}

log ""
log "════════════════════════════════════════════════════"
log "Service script started (FAST=$FAST_MODE)"

API=$(getprop ro.build.version.sdk)
log "Android API: $API"

if [ "$FAST_MODE" != "1" ]; then
    count=0
    while [ "$(getprop sys.boot_completed)" != "1" ] && [ $count -lt 60 ]; do
        sleep 1
        count=$((count + 1))
    done
    log "Boot completed (${count}s)"
fi

# Magic Mount already covers /system/etc/security/cacerts on older Android
if [ "$API" -lt 34 ]; then
    log "Android < 14, APEX injection not needed"
    exit 0
fi

mkdir -p "$CERT_DIR"
CERT_COUNT=$(find "$CERT_DIR" -maxdepth 1 -type f -name "*.[0-9]*" 2>/dev/null | wc -l)
CERT_COUNT=$(echo "$CERT_COUNT" | tr -d ' ')

if [ "$CERT_COUNT" = "0" ] || [ -z "$CERT_COUNT" ]; then
    log "No certificates present in module. Nothing to inject."
    log "Tip: upload a certificate via the WebUI."
    exit 0
fi

log "User certificates: $CERT_COUNT"

# Rebuild tmpfs from scratch so WebUI-driven cert add/delete is reflected
log "Rebuilding tmpfs cert view..."
umount -l "$APEX_CACERTS" 2>/dev/null
umount -l "$TEMP_DIR" 2>/dev/null
rm -rf "$TEMP_DIR" 2>/dev/null
mkdir -p "$TEMP_DIR"

if ! mount -t tmpfs tmpfs "$TEMP_DIR"; then
    log "ERROR: Failed to mount tmpfs"
    exit 1
fi

cp -a "$APEX_CACERTS"/*.[0-9]* "$TEMP_DIR/" 2>/dev/null

for CERT_FILE in "$CERT_DIR"/*.[0-9]*; do
    [ -f "$CERT_FILE" ] || continue
    cp -f "$CERT_FILE" "$TEMP_DIR/$(basename "$CERT_FILE")"
done

chown -R 0:0 "$TEMP_DIR"
chmod 755 "$TEMP_DIR"
chmod 644 "$TEMP_DIR"/*

APEX_CONTEXT=$(ls -Zd "$APEX_CACERTS" 2>/dev/null | awk '{print $1}')
if [ -n "$APEX_CONTEXT" ] && [ "$APEX_CONTEXT" != "?" ]; then
    chcon -R "$APEX_CONTEXT" "$TEMP_DIR" 2>/dev/null
fi

log "Injecting to namespaces..."
mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null && log "✓ Global mount"
nsenter --mount=/proc/1/ns/mnt -- mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null && log "✓ Init (PID 1)"

for zygote in zygote zygote64; do
    PID=$(pidof "$zygote" 2>/dev/null)
    if [ -n "$PID" ]; then
        nsenter --mount=/proc/$PID/ns/mnt -- mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null && log "✓ $zygote (PID $PID)"
    fi
done

# Settings app (for Trusted Credentials visibility)
SETTINGS_PID=$(pidof com.android.settings 2>/dev/null)
if [ -n "$SETTINGS_PID" ]; then
    nsenter --mount=/proc/$SETTINGS_PID/ns/mnt -- mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null && log "✓ Settings (PID $SETTINGS_PID)"
fi

# Common HTTPS interception apps if running (best-effort)
for pkg in com.proxy.pin com.network.proxy com.network.proxy.flutter \
           tech.httptoolkit.android.v1 com.reqable.android \
           com.google.android.gms com.android.chrome com.android.vending; do
    PID=$(pidof "$pkg" 2>/dev/null)
    if [ -n "$PID" ]; then
        nsenter --mount=/proc/$PID/ns/mnt -- mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null && log "✓ $pkg (PID $PID)"
    fi
done

sleep 1
MISSING=0
for CERT_FILE in "$CERT_DIR"/*.[0-9]*; do
    [ -f "$CERT_FILE" ] || continue
    NAME=$(basename "$CERT_FILE")
    if [ -f "$APEX_CACERTS/$NAME" ]; then
        log "✓ $NAME visible in APEX"
    else
        log "✗ $NAME not visible"
        MISSING=$((MISSING+1))
    fi
done
[ "$MISSING" -eq 0 ] && log "✓ SUCCESS: all certificates visible"

APEX_COUNT=$(ls -1 "$APEX_CACERTS"/*.[0-9]* 2>/dev/null | wc -l)
log "Total APEX certs: $APEX_COUNT"

log ""
log "Service completed"
log "════════════════════════════════════════════════════"
