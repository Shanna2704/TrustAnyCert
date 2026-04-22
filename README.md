# TrustAnyCert

System CA certificate installer for rooted Android, managed from a WebUI.

- Upload any PEM / DER / CRT / CER / P7B / P7C — no manual `<subject_hash>.0` filename wrangling
- Subject hash (OpenSSL `subject_hash_old`) computed in pure JavaScript; no `openssl` binary required on the device
- PKCS#7 bundles are unpacked; each contained certificate is installed individually
- Collision-safe filenames (`.0`, `.1`, `.2`, ...)
- APEX tmpfs bypass for Android 14+ (`com.android.conscrypt` cacerts)
- Works with Magisk, KernelSU, SukiSU and APatch

## Prerequisites

- Rooted device with Magisk, KernelSU, SukiSU or APatch
- Android 5.0+ (API 21+)
- A root manager with WebUI support for the Option A flow below; Option B works without WebUI

## Quick Start

1. Download the latest release from the [Releases](https://github.com/gorkemgun/TrustAnyCert/releases) page
2. Install the ZIP via your root manager
3. Reboot

### Option A: WebUI

Open your root manager → Modules → TrustAnyCert → WebUI.

- Tap to select any certificate file (PEM / DER / CRT / CER / P7B / P7C, or PEM bundle)
- Review the parsed certificate (subject, issuer, validity, target filename) before install
- Manage installed certificates from the same UI (delete, re-inject)
- On Android 14+, tap **Re-inject into APEX** after uploading instead of rebooting

### Option B: Manual placement

Compute the Android filename with OpenSSL:

```shell
openssl x509 -in your-ca.pem -noout -subject_hash_old
# -> e.g. 6187b673
```

Copy the PEM under the module's cert directory and refresh the APEX mount:

```shell
adb push your-ca.pem /sdcard/
adb shell su -c 'cp /sdcard/your-ca.pem \
    /data/adb/modules/trustanycert/system/etc/security/cacerts/6187b673.0'
adb shell su -c 'chmod 0644 \
    /data/adb/modules/trustanycert/system/etc/security/cacerts/6187b673.0'
adb shell su -c 'FAST=1 sh /data/adb/modules/trustanycert/service.sh'
```

### Verifying

Settings → Security → Trusted credentials → System — the uploaded CA should appear there.

## How it works

On Android 13 and earlier, the module places certificates under
`/system/etc/security/cacerts/`; the root manager's magic mount makes them
visible to the real system trust store.

On Android 14+, CA certificates live inside the `com.android.conscrypt` APEX,
which is read-only. At boot, `post-fs-data.sh` copies the APEX's default trust
store plus the module-supplied certificates into a tmpfs, then bind-mounts that
tmpfs over `/apex/com.android.conscrypt/cacerts` in the init, zygote and
zygote64 mount namespaces. `service.sh` re-runs the same step post-boot (and on
demand from the WebUI) to cover app processes that spawn in separate namespaces.

## Paths

| Path | Purpose |
|------|---------|
| `/data/adb/modules/trustanycert/system/etc/security/cacerts/` | Installed certificates (`<subject_hash>.<N>`, where `N` starts at 0 and increments on collision) |
| `/data/local/tmp/trustanycert.log` | Module log (post-fs-data / service / uninstall) |
| `/data/local/tmp/trustanycert-apex-ca` | tmpfs staging directory on Android 14+ |

## Building

Local build needs `bash`, `zip`, `node` 20+ and `openssl` on `PATH`:

```shell
./test.sh    # structure / shell syntax / cert.js smoke tests
./build.sh   # dist/TrustAnyCert-<version>.zip
```

Override the version explicitly with `./build.sh vX.Y`; otherwise it is read
from `module.prop`.

### With Docker

```shell
docker build -t trustanycert-build .
docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/src" trustanycert-build
```

Sub-commands: `test`, `build [version]`, `shell`.

### Cutting a release

1. Bump `version` and `versionCode` in `module.prop`
2. Update `update.json` with the new tag URL
3. `git tag vX.Y && git push --tags`

`release.yml` verifies the tag matches `module.prop`, runs `test.sh` and
`build.sh`, then publishes a GitHub Release with auto-generated notes.

## Credits

- [firdausmntp](https://github.com/firdausmntp) — [ProxyPin-cert-installer](https://github.com/firdausmntp/ProxyPin-cert-installer) v1.0, which the boot / APEX injection scripts were adapted from
- [wanghongenpin](https://github.com/wanghongenpin) — [Magisk-ProxyPinCA](https://github.com/wanghongenpin/Magisk-ProxyPinCA), original module the v1.0 above was itself based on
- [NVISOsecurity](https://github.com/NVISOsecurity) — [AlwaysTrustUserCerts](https://github.com/NVISOsecurity/AlwaysTrustUserCerts), prior art on promoting user-store CAs to the system store on Android 14
- [topjohnwu](https://github.com/topjohnwu) — Magisk
- [tiann](https://github.com/tiann) — KernelSU
- [pomelohan](https://github.com/pomelohan/SukiSU-Ultra) — SukiSU
- [bmax121](https://github.com/bmax121) — APatch
