#!/bin/sh
# Native Linux build for modern arches (x86_64, etc.).
# Uses system pkg-config / OpenSSL via the Autotools linux-gnu * path.
#
# Usage:
#   ./build-linux-native.sh           # incremental make
#   ./build-linux-native.sh release   # autoreconf + configure + make + deploy
#   ./build-linux-native.sh clean     # distclean generated files

set -e

ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
cd "$ROOT"

TARGET=$(uname -m)-linux-gnu
JOBS=$(nproc 2>/dev/null || echo 2)
MODE=${1:-}

clean_autotools() {
    if [ -f Makefile ]; then
        make distclean || make clean || true
    fi
    rm -rf aclocal.m4 autom4te.cache/ compile config.guess config.log \
        config.status config.sub configure depcomp install-sh libtool \
        ltmain.sh m4/ Makefile.in missing Makefile
    find . -name '*.in' ! -name 'Makefile.am' -exec rm -f {} + 2>/dev/null || true
}

echo "### Building core... ###"
cd "$ROOT/core"
case "$MODE" in
    release)
        autoreconf --install
        ./configure
        make -j"$JOBS"
        ;;
    clean)
        clean_autotools
        ;;
    *)
        if [ ! -f Makefile ]; then
            autoreconf --install
            ./configure
        fi
        make -j"$JOBS"
        ;;
esac
cd "$ROOT"

echo "### Building modules... ###"
cd "$ROOT/modules"
case "$MODE" in
    release)
        autoreconf --install
        ./configure
        make -j"$JOBS"
        ;;
    clean)
        clean_autotools
        ;;
    *)
        if [ ! -f Makefile ]; then
            autoreconf --install
            ./configure
        fi
        make -j"$JOBS"
        ;;
esac
cd "$ROOT"

echo "### Building tools... ###"
cd "$ROOT/tools/moddesc"
case "$MODE" in
    release)
        autoreconf --install
        ./configure
        make -j"$JOBS"
        ;;
    clean)
        clean_autotools
        ;;
    *)
        if [ ! -f Makefile ]; then
            autoreconf --install
            ./configure
        fi
        make -j"$JOBS"
        ;;
esac
cd "$ROOT"

if [ "$MODE" = clean ]; then
    rm -rf "bin/${TARGET}"
    echo "### Clean done ###"
    exit 0
fi

echo "### Deploying to bin/${TARGET}... ###"
mkdir -p "bin/${TARGET}"
cp -f core/bgdi/src/.libs/bgdi "bin/${TARGET}/"
cp -f core/bgdc/src/bgdc "bin/${TARGET}/"
cp -f core/bgdrtm/src/.libs/libbgdrtm.so "bin/${TARGET}/"
find modules -name '*.so' -exec cp -f {} "bin/${TARGET}/" \;
# bgdc/bgdi load "mod_foo.so"; libtool emits libmod_foo.so
for f in "bin/${TARGET}"/libmod_*.so; do
    [ -e "$f" ] || continue
    base=$(basename "$f")
    ln -sfn "$base" "bin/${TARGET}/${base#lib}"
done
if [ -f tools/moddesc/moddesc ]; then
    cp -f tools/moddesc/moddesc "bin/${TARGET}/"
elif [ -f tools/moddesc/.libs/moddesc ]; then
    cp -f tools/moddesc/.libs/moddesc "bin/${TARGET}/"
fi

echo "### Stripping... ###"
strip "bin/${TARGET}/bgdi" "bin/${TARGET}/bgdc" "bin/${TARGET}/libbgdrtm.so" || true
[ -f "bin/${TARGET}/moddesc" ] && strip "bin/${TARGET}/moddesc" || true
find "bin/${TARGET}" -name '*.so' -exec strip {} \; || true

echo "### Done! Binaries in bin/${TARGET} ###"
echo "Example:"
echo "  export LD_LIBRARY_PATH=\"$ROOT/bin/${TARGET}:\$LD_LIBRARY_PATH\""
echo "  $ROOT/bin/${TARGET}/bgdc game.prg && $ROOT/bin/${TARGET}/bgdi game.dcb"
