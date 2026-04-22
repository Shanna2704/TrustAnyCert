# Tests

`smoke.js` exercises `webroot/cert.js` against a real, publicly distributed
CA so the Android `subject_hash_old` algorithm stays provably correct.

## Fixture

[`fixtures/isrg-root-x1.pem`](fixtures/isrg-root-x1.pem) — the Let's Encrypt
"ISRG Root X1" root CA. Public, self-signed, universally available
(Ubuntu / macOS / Debian / etc. all ship it in their trust store).

Expected values, verified with `openssl`:

```
$ openssl x509 -in tests/fixtures/isrg-root-x1.pem -noout -subject_hash_old
6187b673
```

## Running

```bash
./test.sh
```

or directly:

```bash
node tests/smoke.js
```

The test needs `openssl` in PATH to generate DER and PKCS#7 variants on the
fly — no extra fixtures are checked in for those.
