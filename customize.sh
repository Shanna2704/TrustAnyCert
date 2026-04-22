#!/system/bin/sh
# Android 5.0 - 16 (API 21-36) compatible
SKIPUNZIP=0

print_banner() {
    ui_print "╔════════════════════════════════════════╗"
    ui_print "║  TrustAnyCert v1.0                     ║"
    ui_print "║  Universal CA installer (WebUI)        ║"
    ui_print "╚════════════════════════════════════════╝"
    ui_print ""
}

detect_root_solution() {
    if [ "$KSU" = "true" ]; then
        # Check for SukiSU specifically
        if [ -f /data/adb/ksu/bin/ksud ]; then
            if strings /data/adb/ksu/bin/ksud 2>/dev/null | grep -qi "sukisu"; then
                ROOT_IMPL="SukiSU"
            else
                ROOT_IMPL="KernelSU"
            fi
        else
            ROOT_IMPL="KernelSU"
        fi
        ROOT_VER="$KSU_VER"
        ROOT_VER_CODE="$KSU_VER_CODE"
    elif [ "$APATCH" = "true" ]; then
        ROOT_IMPL="APatch"
        ROOT_VER="$APATCH_VER"
        ROOT_VER_CODE="$APATCH_VER_CODE"
    else
        ROOT_IMPL="Magisk"
        ROOT_VER="$MAGISK_VER"
        ROOT_VER_CODE="$MAGISK_VER_CODE"
    fi
}

check_compatibility() {
    API=$(getprop ro.build.version.sdk)
    [ -z "$API" ] && API=21

    if [ "$API" -lt 21 ]; then
        abort "! ERROR: Minimum Android 5.0 (API 21) required!"
    fi

    if [ "$API" -gt 36 ]; then
        ui_print "! WARNING: Untested Android version (API $API)"
        ui_print "  Proceeding anyway..."
    fi

    case "$ROOT_IMPL" in
        "Magisk")
            [ "$ROOT_VER_CODE" -lt 20400 ] && abort "! ERROR: Magisk v20.4+ required!"
            ;;
        "KernelSU"|"SukiSU")
            if [ "$ROOT_VER_CODE" -lt 10000 ]; then
                ui_print "! WARNING: Old $ROOT_IMPL version"
            fi
            ;;
        "APatch")
            if [ "$ROOT_VER_CODE" -lt 10300 ]; then
                ui_print "! WARNING: Old APatch version"
            fi
            ;;
    esac
}

setup_permissions() {
    ui_print "- Setting permissions..."

    if [ -d "$MODPATH/system/etc/security/cacerts" ]; then
        set_perm_recursive "$MODPATH/system/etc/security/cacerts" 0 0 0755 0644
    fi

    for script in post-fs-data.sh service.sh uninstall.sh action.sh; do
        [ -f "$MODPATH/$script" ] && set_perm "$MODPATH/$script" 0 0 0755
    done

    if [ -d "$MODPATH/webroot" ]; then
        set_perm_recursive "$MODPATH/webroot" 0 0 0755 0644
    fi
}

cleanup_certificates() {
    local CERT_DIR="$MODPATH/system/etc/security/cacerts"

    mkdir -p "$CERT_DIR"
    rm -f "$CERT_DIR/.gitkeep" "$CERT_DIR/README.md" 2>/dev/null

    # Keep only valid cert filenames (<hash>.<N>); strip anything else
    for file in "$CERT_DIR"/*; do
        if [ -f "$file" ]; then
            case "$(basename "$file")" in
                *.[0-9]|*.[0-9][0-9])
                    ;;
                *)
                    rm -f "$file"
                    ui_print "  Removed $(basename "$file")"
                    ;;
            esac
        fi
    done
}

check_certificate() {
    local cert_dir="$MODPATH/system/etc/security/cacerts"
    local cert_count=$(find "$cert_dir" -maxdepth 1 -type f -name "*.[0-9]*" 2>/dev/null | wc -l)
    cert_count=$(echo "$cert_count" | tr -d ' ')

    if [ -n "$cert_count" ] && [ "$cert_count" -gt 0 ]; then
        ui_print "- Found $cert_count pre-bundled certificate(s):"
        find "$cert_dir" -maxdepth 1 -type f -name "*.[0-9]*" 2>/dev/null | while read cert; do
            ui_print "    $(basename "$cert")"
        done
    fi
}

setup_android14_plus() {
    API=$(getprop ro.build.version.sdk)

    if [ "$API" -ge 34 ]; then
        ui_print "- Android 14+ detected (API $API)"
        ui_print "- APEX CA bypass will be configured"
        chmod 0755 "$MODPATH/post-fs-data.sh" 2>/dev/null
        chmod 0755 "$MODPATH/service.sh" 2>/dev/null
    fi
}

print_summary() {
    ui_print ""
    ui_print "╔════════════════════════════════════════╗"
    ui_print "║  ✓ TrustAnyCert installed              ║"
    ui_print "╚════════════════════════════════════════╝"
    ui_print ""
    ui_print "  Root Solution: $ROOT_IMPL ($ROOT_VER)"
    ui_print "  Android API:   $API"
    ui_print ""
    ui_print "  Next steps:"
    ui_print "    1. Open WebUI via your root manager"
    ui_print "    2. Upload a CA certificate (PEM/DER/CRT/CER/P7B)"
    ui_print "    3. Reboot (or tap Re-inject for Android 14+)"
    ui_print "    4. Check: Settings → Security → Trusted credentials"
    ui_print ""
    ui_print "  Logs: /data/local/tmp/trustanycert.log"
    ui_print ""
}

print_banner
detect_root_solution

ui_print "- Detected: $ROOT_IMPL"
ui_print "- Version:  $ROOT_VER (code: $ROOT_VER_CODE)"
ui_print ""

check_compatibility
setup_permissions
cleanup_certificates
check_certificate
setup_android14_plus
print_summary