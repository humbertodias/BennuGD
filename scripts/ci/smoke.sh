#!/usr/bin/env bash
# Smoke-test bgdc/bgdi after a native build.
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)

OS=$(uname -s)
ARCH=$(uname -m)
case "$OS" in
  Darwin)
    TARGET=${TARGET:-${ARCH}-apple-darwin}
    ;;
  *)
    TARGET=${TARGET:-${ARCH}-linux-gnu}
    ;;
esac

BIN="$ROOT/bin/$TARGET"

if [[ ! -x "$BIN/bgdc" || ! -x "$BIN/bgdi" ]]; then
  echo "Missing binaries in $BIN" >&2
  ls -la "$BIN" >&2 || true
  exit 1
fi

if [[ "$OS" == Darwin ]]; then
  export DYLD_LIBRARY_PATH="$BIN${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
else
  export LD_LIBRARY_PATH="$BIN${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

echo "bgdc=$BIN/bgdc"
echo "bgdi=$BIN/bgdi"

"$BIN/bgdc" >/tmp/bgdc-help.txt 2>&1 || true
"$BIN/bgdi" >/tmp/bgdi-help.txt 2>&1 || true
grep -E 'BGDC|Compiler' /tmp/bgdc-help.txt
grep -E 'BGDI|Interpreter' /tmp/bgdi-help.txt

echo "Dynamic libs (informational):"
if [[ "$OS" == Darwin ]]; then
  otool -L "$BIN/bgdi" | head -40 || true
else
  ldd "$BIN/bgdi" | head -40 || true
fi

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

# Video path (headless-friendly)
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-dummy}"
cat > "$TMP/video.prg" <<'EOF'
import "mod_video"
import "mod_say"
Process Main()
Begin
    set_mode(320,200,32);
    say("video-ok");
End
EOF
"$BIN/bgdc" "$TMP/video.prg"
"$BIN/bgdi" "$TMP/video.dcb" | tee /tmp/bgdi-video.txt
grep -q 'video-ok' /tmp/bgdi-video.txt

echo "Smoke tests passed."
