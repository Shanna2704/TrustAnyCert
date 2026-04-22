// Smoke test for webroot/cert.js.
// Validates:
//  1. cert.js loads and exports TrustAnyCert namespace
//  2. Parses a known public CA (ISRG Root X1) in PEM form
//  3. Computes the Android subject_hash_old (6187b673) correctly
//  4. Handles DER input the same way
//  5. Handles PKCS#7 bundle input
//
// Fixture: tests/fixtures/isrg-root-x1.pem (Let's Encrypt root, public).

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

// Minimal browser-like globals for cert.js
global.window = global;
global.atob = (s) => Buffer.from(s, 'base64').toString('binary');
global.btoa = (s) => Buffer.from(s, 'binary').toString('base64');
global.TextEncoder = require('util').TextEncoder;
global.TextDecoder = require('util').TextDecoder;
global.crypto = require('crypto').webcrypto;

require(path.join(__dirname, '..', 'webroot', 'cert.js'));

const FIXTURE = path.join(__dirname, 'fixtures', 'isrg-root-x1.pem');
const EXPECTED_HASH = '6187b673';
const EXPECTED_CN = 'ISRG Root X1';

function assert(cond, msg) {
    if (!cond) {
        console.error('  FAIL: ' + msg);
        process.exit(1);
    }
}

(async () => {
    assert(typeof global.TrustAnyCert === 'object',
        'global.TrustAnyCert not exported');
    assert(typeof global.TrustAnyCert.parseCertificateFile === 'function',
        'parseCertificateFile missing');

    const pem = fs.readFileSync(FIXTURE);

    // 1. PEM
    {
        const parsed = await global.TrustAnyCert.parseCertificateFile(new Uint8Array(pem));
        assert(parsed.length === 1,     'PEM: expected 1 cert, got ' + parsed.length);
        assert(parsed[0].hash === EXPECTED_HASH,
            `PEM: expected hash ${EXPECTED_HASH}, got ${parsed[0].hash}`);
        assert(parsed[0].subjectCN === EXPECTED_CN,
            `PEM: expected CN "${EXPECTED_CN}", got "${parsed[0].subjectCN}"`);
        assert(parsed[0].selfSigned === true, 'PEM: expected selfSigned=true');
        assert(parsed[0].sourceFormat === 'pem', 'PEM: sourceFormat=' + parsed[0].sourceFormat);
        console.log(`  pem:     ${parsed[0].hash}.0  ${parsed[0].subjectCN}`);
    }

    // 2. DER (convert via openssl)
    {
        const derPath = path.join(__dirname, 'fixtures', '.isrg-root-x1.der');
        execFileSync('openssl',
            ['x509', '-in', FIXTURE, '-outform', 'DER', '-out', derPath]);
        const der = fs.readFileSync(derPath);
        fs.unlinkSync(derPath);
        const parsed = await global.TrustAnyCert.parseCertificateFile(new Uint8Array(der));
        assert(parsed.length === 1, 'DER: expected 1 cert');
        assert(parsed[0].hash === EXPECTED_HASH,
            `DER: expected hash ${EXPECTED_HASH}, got ${parsed[0].hash}`);
        assert(parsed[0].sourceFormat === 'der', 'DER: sourceFormat=' + parsed[0].sourceFormat);
        console.log(`  der:     ${parsed[0].hash}.0  ${parsed[0].subjectCN}`);
    }

    // 3. PKCS#7 bundle (two certs in one file)
    {
        const p7bPath = path.join(__dirname, 'fixtures', '.bundle.p7b');
        execFileSync('openssl',
            ['crl2pkcs7', '-nocrl', '-certfile', FIXTURE, '-out', p7bPath]);
        const p7b = fs.readFileSync(p7bPath);
        fs.unlinkSync(p7bPath);
        const parsed = await global.TrustAnyCert.parseCertificateFile(new Uint8Array(p7b));
        assert(parsed.length >= 1, 'PKCS7: expected at least 1 cert');
        const found = parsed.find(c => c.hash === EXPECTED_HASH);
        assert(found, `PKCS7: did not find ${EXPECTED_HASH} in bundle`);
        console.log(`  pkcs7:   ${found.hash}.0  ${found.subjectCN}`);
    }

    // 4. Garbage input must throw
    {
        let threw = false;
        try { await global.TrustAnyCert.parseCertificateFile(new Uint8Array([0, 1, 2, 3])); }
        catch (e) { threw = true; }
        assert(threw, 'garbage: expected parse error');
        console.log('  garbage: throws as expected');
    }

    console.log('  all smoke tests passed');
})().catch(e => {
    console.error('  FAIL: ' + (e && e.stack || e));
    process.exit(1);
});
