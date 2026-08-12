#!/usr/bin/env bash
# Stage native build outputs for CI artifacts / releases.
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)

OS=$(uname -s)
ARCH=$(uname -m)
case "$OS" in
  Darwin)
    PLATFORM=${PLATFORM:-macos}
    TARGET=${TARGET:-${ARCH}-apple-darwin}
    SHLIB_EXT=dylib
    ;;
  MINGW*|MSYS*|CYGWIN*)
    PLATFORM=${PLATFORM:-windows}
    TARGET=${TARGET:-${ARCH}-w64-mingw32}
    SHLIB_EXT=dll
    ;;
  *)
    if [[ -n "${MSYSTEM:-}" ]]; then
      PLATFORM=${PLATFORM:-windows}
      TARGET=${TARGET:-${ARCH}-w64-mingw32}
      SHLIB_EXT=dll
    else
      PLATFORM=${PLATFORM:-linux}
      TARGET=${TARGET:-${ARCH}-linux-gnu}
      SHLIB_EXT=so
    fi
    ;;
esac

VERSION=${VERSION:-dev}
DIST_DIR=${DIST_DIR:-"$ROOT/dist"}
STAGE_NAME="bennugd-${VERSION}-${PLATFORM}-${ARCH}"
STAGE="$DIST_DIR/stage/$STAGE_NAME"
BIN="$ROOT/bin/$TARGET"

if [[ ! -d "$BIN" ]]; then
  echo "Missing build output: $BIN" >&2
  exit 1
fi

rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -a "$BIN"/. "$STAGE/"

# Prefer stable module names without libtool "lib" prefix.
shopt -s nullglob
for f in "$STAGE"/libmod_*."$SHLIB_EXT"; do
  [[ -e "$f" ]] || continue
  base=$(basename "$f")
  dest="$STAGE/${base#lib}"
  if [[ "$PLATFORM" == "windows" ]]; then
    cp -f "$f" "$dest"
  else
    ln -sfn "$base" "$dest"
  fi
done

if [[ "$PLATFORM" == "macos" ]]; then
  RUN_HINT=$(cat <<'EOF'
  export DYLD_LIBRARY_PATH="$PWD:$PWD/lib:$DYLD_LIBRARY_PATH"
EOF
)
elif [[ "$PLATFORM" == "windows" ]]; then
  RUN_HINT=$(cat <<'EOF'
  # Keep DLLs next to the .exe (or add this folder to PATH).
EOF
)
else
  RUN_HINT=$(cat <<'EOF'
  export LD_LIBRARY_PATH="$PWD:$PWD/lib:$LD_LIBRARY_PATH"
EOF
)
fi

EXE_SUFFIX=
[[ "$PLATFORM" == "windows" ]] && EXE_SUFFIX=.exe

cat > "$STAGE/README.txt" <<EOF
BennuGD ${VERSION} (${PLATFORM}-${ARCH})

Contents: bgdc, bgdi, libbgdrtm, modules (mod_*).

Run with:
${RUN_HINT}
  ./bgdc${EXE_SUFFIX} game.prg
  ./bgdi${EXE_SUFFIX} game.dcb
EOF

echo "Staged $STAGE"
find "$STAGE" -maxdepth 1 \( -type f -o -type l \) | sort | head -80
