# Changelog

## v1.0

Initial release.

- WebUI upload for PEM, DER, CRT, CER, P7B, P7C and PEM bundles
- `subject_hash_old` (MD5-based `X509_NAME_hash_old`) computed in the browser
- PKCS#7 bundles are unpacked; each contained certificate is installed individually
- Collision-safe filenames (`.0`, `.1`, `.2`, ...)
- Installed certificate list in WebUI, with per-cert delete
- APEX tmpfs bypass for Android 14+ (`com.android.conscrypt` cacerts)
- `service.sh` honours `FAST=1` so the WebUI Re-inject action skips the boot-wait loop
- Works with Magisk, KernelSU, SukiSU and APatch
