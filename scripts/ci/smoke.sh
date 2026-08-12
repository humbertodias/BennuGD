#!/usr/bin/env bash
# Smoke-test bgdc/bgdi after a native build.
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
TARGET=${TARGET:-$(uname -m)-linux-gnu}
BIN="$ROOT/bin/$TARGET"

if [[ ! -x "$BIN/bgdc" || ! -x "$BIN/bgdi" ]]; then
  echo "Missing binaries in $BIN" >&2
  ls -la "$BIN" >&2 || true
  exit 1
fi

export LD_LIBRARY_PATH="$BIN${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

echo "bgdc=$BIN/bgdc"
echo "bgdi=$BIN/bgdi"

"$BIN/bgdc" >/tmp/bgdc-help.txt 2>&1 || true
"$BIN/bgdi" >/tmp/bgdi-help.txt 2>&1 || true
grep -E 'BGDC|Compiler' /tmp/bgdc-help.txt
grep -E 'BGDI|Interpreter' /tmp/bgdi-help.txt

echo "Dynamic libs (informational):"
ldd "$BIN/bgdi" | head -40 || true

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/smoke.prg" <<'EOF'
import "mod_say"
import "mod_string"
import "mod_mem"

Process Main()
Private
    int p;
Begin
    p = alloc(16);
    memset(p, 0, 16);
    say("ci-ok");
    free(p);
End
EOF

"$BIN/bgdc" "$TMP/smoke.prg"
test -f "$TMP/smoke.dcb"
"$BIN/bgdi" "$TMP/smoke.dcb" | tee /tmp/bgdi-smoke.txt
grep -q 'ci-ok' /tmp/bgdi-smoke.txt

echo "Smoke tests passed."
