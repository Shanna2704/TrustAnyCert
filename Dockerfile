# Local build image for TrustAnyCert.
#
# Usage:
#   docker build -t trustanycert-build .
#   docker run --rm -v "$PWD:/src" trustanycert-build          # test + build
#   docker run --rm -v "$PWD:/src" trustanycert-build test     # tests only
#   docker run --rm -v "$PWD:/src" trustanycert-build build    # build only
#   docker run --rm -v "$PWD:/src" trustanycert-build shell    # interactive
#
# The output zip lands in ./dist/ on the host.

FROM alpine:3.19

# Build / test dependencies:
#   - bash        build.sh + test.sh
#   - zip         packaging
#   - nodejs      cert.js smoke test
#   - openssl     DER / PKCS#7 generation in smoke test
#   - ca-certificates so the sample ISRG Root X1 fixture is also available
#     locally for manual experimentation (optional)
RUN apk add --no-cache bash zip nodejs openssl ca-certificates

WORKDIR /src

COPY <<'EOF' /usr/local/bin/entrypoint.sh
#!/usr/bin/env bash
set -euo pipefail
cmd="${1:-all}"
shift || true
case "$cmd" in
    test)   exec ./test.sh ;;
    build)  exec ./build.sh "$@" ;;
    all)    ./test.sh && exec ./build.sh "$@" ;;
    shell)  exec bash "$@" ;;
    *)      exec "$cmd" "$@" ;;
esac
EOF
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["all"]
