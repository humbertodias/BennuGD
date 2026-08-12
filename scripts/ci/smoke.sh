#!/usr/bin/env bash
# Smoke-test bgdc/bgdi after a native build.
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)

OS=$(uname -s)
ARCH=$(uname -m)
case "$OS" in
  Darwin)
    TARGET=${TARGET:-${ARCH}-apple-darwin}
    EXE=
    ;;
  MINGW*|MSYS*|CYGWIN*)
    TARGET=${TARGET:-${ARCH}-w64-mingw32}
    EXE=.exe
    ;;
  *)
    if [[ -n "${MSYSTEM:-}" ]]; then
      TARGET=${TARGET:-${ARCH}-w64-mingw32}
      EXE=.exe
    else
      TARGET=${TARGET:-${ARCH}-linux-gnu}
      EXE=
    fi
    ;;
esac

BIN="$ROOT/bin/$TARGET"
BGDC="$BIN/bgdc${EXE}"
BGDI="$BIN/bgdi${EXE}"

if [[ ! -x "$BGDC" || ! -x "$BGDI" ]]; then
  echo "Missing binaries in $BIN" >&2
  ls -la "$BIN" >&2 || true
  exit 1
fi

case "$OS" in
  Darwin)
    export DYLD_LIBRARY_PATH="$BIN${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    export PATH="$BIN${PATH:+:$PATH}"
    ;;
  *)
    if [[ -n "${MSYSTEM:-}" ]]; then
      export PATH="$BIN${PATH:+:$PATH}"
    else
      export LD_LIBRARY_PATH="$BIN${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    fi
    ;;
esac

echo "bgdc=$BGDC"
echo "bgdi=$BGDI"

"$BGDC" >/tmp/bgdc-help.txt 2>&1 || true
"$BGDI" >/tmp/bgdi-help.txt 2>&1 || true
grep -E 'BGDC|Compiler' /tmp/bgdc-help.txt
grep -E 'BGDI|Interpreter' /tmp/bgdi-help.txt

echo "Dynamic libs (informational):"
case "$OS" in
  Darwin)
    otool -L "$BGDI" | head -40 || true
    ;;
  MINGW*|MSYS*|CYGWIN*)
    objdump -p "$BGDI" | grep -i 'DLL Name' | head -40 || true
    ;;
  *)
    if [[ -n "${MSYSTEM:-}" ]]; then
      objdump -p "$BGDI" | grep -i 'DLL Name' | head -40 || true
    else
      ldd "$BGDI" | head -40 || true
    fi
    ;;
esac

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

"$BGDC" "$TMP/smoke.prg"
test -f "$TMP/smoke.dcb"
"$BGDI" "$TMP/smoke.dcb" | tee /tmp/bgdi-smoke.txt
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
"$BGDC" "$TMP/video.prg"
"$BGDI" "$TMP/video.dcb" | tee /tmp/bgdi-video.txt
grep -q 'video-ok' /tmp/bgdi-video.txt

echo "Smoke tests passed."
