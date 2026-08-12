#!/usr/bin/env bash
# Stage native build outputs for CI artifacts / releases.
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
TARGET=${TARGET:-$(uname -m)-linux-gnu}
VERSION=${VERSION:-dev}
DIST_DIR=${DIST_DIR:-"$ROOT/dist"}
STAGE_NAME="bennugd-${VERSION}-linux-x86_64"
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
for f in "$STAGE"/libmod_*.so; do
  [[ -e "$f" ]] || continue
  base=$(basename "$f")
  ln -sfn "$base" "$STAGE/${base#lib}"
done

cat > "$STAGE/README.txt" <<EOF
BennuGD ${VERSION} (linux-x86_64)

Contents: bgdc, bgdi, libbgdrtm.so, modules (mod_*.so).

Run with:
  export LD_LIBRARY_PATH="\$PWD:\$LD_LIBRARY_PATH"
  ./bgdc game.prg
  ./bgdi game.dcb
EOF

echo "Staged $STAGE"
find "$STAGE" -maxdepth 1 -type f -o -type l | sort | head -80
