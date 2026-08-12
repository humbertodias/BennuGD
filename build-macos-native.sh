#!/bin/sh
# Native macOS build (arm64 / x86_64).
# Uses pkg-config for SDL3 / SDL3_mixer / OpenSSL via Autotools.
#
# Usage:
#   ./build-macos-native.sh           # incremental make
#   ./build-macos-native.sh release   # autoreconf + configure + make + deploy
#   ./build-macos-native.sh clean     # distclean generated files
#
# Optional: source scripts/ci build env first if SDL3 lives in a custom prefix:
#   source .deps/env.sh && ./build-macos-native.sh release
#
# Homebrew tip (Apple Silicon):
#   brew install automake autoconf libtool pkg-config openssl@3 libpng
#   export PKG_CONFIG_PATH="$(brew --prefix openssl@3)/lib/pkgconfig:$(brew --prefix libpng)/lib/pkgconfig"

set -e

ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
cd "$ROOT"

case "$(uname -s)" in
    Darwin) ;;
    *)
        echo "build-macos-native.sh is for macOS only; use ./build-linux-native.sh on Linux." >&2
        exit 1
        ;;
esac

TARGET=$(uname -m)-apple-darwin
JOBS=$(sysctl -n hw.ncpu 2>/dev/null || echo 2)
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

echo "### Building core ($TARGET)... ###"
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

if [ -x core/bgdi/src/.libs/bgdi ]; then
    cp -f core/bgdi/src/.libs/bgdi "bin/${TARGET}/"
elif [ -x core/bgdi/src/bgdi ]; then
    cp -f core/bgdi/src/bgdi "bin/${TARGET}/"
fi
if [ -x core/bgdc/src/bgdc ]; then
    cp -f core/bgdc/src/bgdc "bin/${TARGET}/"
elif [ -x core/bgdc/src/.libs/bgdc ]; then
    cp -f core/bgdc/src/.libs/bgdc "bin/${TARGET}/"
fi

cp -f core/bgdrtm/src/.libs/libbgdrtm.dylib "bin/${TARGET}/" 2>/dev/null || \
    cp -f core/bgdrtm/src/.libs/libbgdrtm.*.dylib "bin/${TARGET}/"

find modules -name '*.dylib' -exec cp -f {} "bin/${TARGET}/" \;

# bgdi loads "mod_foo.dylib"; libtool emits libmod_foo.dylib
for f in "bin/${TARGET}"/libmod_*.dylib; do
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
strip "bin/${TARGET}/bgdi" "bin/${TARGET}/bgdc" 2>/dev/null || true
strip -x "bin/${TARGET}"/libbgdrtm*.dylib 2>/dev/null || true
[ -f "bin/${TARGET}/moddesc" ] && strip "bin/${TARGET}/moddesc" 2>/dev/null || true
find "bin/${TARGET}" -name '*.dylib' -exec strip -x {} \; 2>/dev/null || true

echo "### Done! Binaries in bin/${TARGET} ###"
echo "Example:"
echo "  export DYLD_LIBRARY_PATH=\"$ROOT/bin/${TARGET}:\$DYLD_LIBRARY_PATH\""
echo "  $ROOT/bin/${TARGET}/bgdc game.prg && $ROOT/bin/${TARGET}/bgdi game.dcb"
