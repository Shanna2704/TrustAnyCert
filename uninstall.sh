#!/system/bin/sh
# Unmount APEX bind and remove staging tmpfs when the module is uninstalled.

MODDIR=${0%/*}
LOG_FILE="/data/local/tmp/trustanycert.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [uninstall] $1" >> "$LOG_FILE"
}

log "Uninstall script started"

unmount_apex() {
    local apex_dir="/apex/com.android.conscrypt/cacerts"
    local temp_dir="/data/local/tmp/trustanycert-apex-ca"

    if mountpoint -q "$apex_dir" 2>/dev/null; then
        umount "$apex_dir" 2>/dev/null
        log "Unmounted APEX CA directory"
    fi

    # Unmount in init + zygote namespaces that service.sh bound into
    for pid in 1 $(pidof zygote 2>/dev/null) $(pidof zygote64 2>/dev/null); do
        if [ -d "/proc/$pid/ns/mnt" ]; then
            nsenter --mount=/proc/$pid/ns/mnt -- \
                umount "$apex_dir" 2>/dev/null
        fi
    done

    if mountpoint -q "$temp_dir" 2>/dev/null; then
        umount "$temp_dir" 2>/dev/null
        log "Unmounted temp directory"
    fi
    rm -rf "$temp_dir" 2>/dev/null
}

cleanup_temp() {
    rm -rf /data/local/tmp/trustanycert-apex-ca 2>/dev/null
    rm -f "$MODDIR/.apex_bypass_needed" 2>/dev/null
    log "Cleaned up temporary files"
}

unmount_apex
cleanup_temp

log "Uninstall completed"
log "NOTE: Reboot recommended to fully remove certificate from system"
