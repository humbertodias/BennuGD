#!/bin/sh
# Native Windows build via MSYS2 MinGW-w64 (UCRT64 / MINGW64).
# Uses pkg-config for SDL3 / SDL3_mixer / OpenSSL via Autotools.
#
# Usage (inside an MSYS2 UCRT64 shell):
#   ./build-windows-native.sh           # incremental make
#   ./build-windows-native.sh release   # autoreconf + configure + make + deploy
#   ./build-windows-native.sh clean     # distclean generated files
#
# Optional: source scripts/ci build env first if SDL3 lives in a custom prefix:
#   source .deps/env.sh && ./build-windows-native.sh release

set -e

ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
cd "$ROOT"

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *)
        if [ -z "${MSYSTEM:-}" ]; then
            echo "build-windows-native.sh is for MSYS2/MinGW only." >&2
            echo "Use ./build-linux-native.sh or ./build-macos-native.sh on other OSes." >&2
            exit 1
        fi
        ;;
esac

TARGET=${TARGET:-$(uname -m)-w64-mingw32}
JOBS=$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)
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

echo "### Building core ($TARGET, MSYSTEM=${MSYSTEM:-?})... ###"
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

# Executables (libtool may place them in .libs/)
if [ -f core/bgdi/src/.libs/bgdi.exe ]; then
    cp -f core/bgdi/src/.libs/bgdi.exe "bin/${TARGET}/"
elif [ -f core/bgdi/src/bgdi.exe ]; then
    cp -f core/bgdi/src/bgdi.exe "bin/${TARGET}/"
else
    echo "bgdi.exe not found" >&2
    exit 1
fi

if [ -f core/bgdc/src/.libs/bgdc.exe ]; then
    cp -f core/bgdc/src/.libs/bgdc.exe "bin/${TARGET}/"
elif [ -f core/bgdc/src/bgdc.exe ]; then
    cp -f core/bgdc/src/bgdc.exe "bin/${TARGET}/"
else
    echo "bgdc.exe not found" >&2
    exit 1
fi

# Runtime DLL (avoid-version => libbgdrtm.dll)
cp -f core/bgdrtm/src/.libs/libbgdrtm*.dll "bin/${TARGET}/" 2>/dev/null || true
if ! ls "bin/${TARGET}"/libbgdrtm*.dll >/dev/null 2>&1; then
    echo "libbgdrtm.dll not found under core/bgdrtm/src/.libs" >&2
    ls -la core/bgdrtm/src/.libs >&2 || true
    exit 1
fi

# Module DLLs from libtool .libs
find modules -path '*/.libs/*.dll' -exec cp -f {} "bin/${TARGET}/" \;

# bgdc/bgdi load "mod_foo.dll"; libtool emits libmod_foo.dll
for f in "bin/${TARGET}"/libmod_*.dll; do
    [ -e "$f" ] || continue
    base=$(basename "$f")
    cp -f "$f" "bin/${TARGET}/${base#lib}"
done

if [ -f tools/moddesc/.libs/moddesc.exe ]; then
    cp -f tools/moddesc/.libs/moddesc.exe "bin/${TARGET}/"
elif [ -f tools/moddesc/moddesc.exe ]; then
    cp -f tools/moddesc/moddesc.exe "bin/${TARGET}/"
fi

echo "### Stripping... ###"
strip "bin/${TARGET}/bgdi.exe" "bin/${TARGET}/bgdc.exe" 2>/dev/null || true
[ -f "bin/${TARGET}/moddesc.exe" ] && strip "bin/${TARGET}/moddesc.exe" 2>/dev/null || true
find "bin/${TARGET}" -name '*.dll' -exec strip {} \; 2>/dev/null || true

echo "### Done! Binaries in bin/${TARGET} ###"
echo "Example:"
echo "  export PATH=\"$ROOT/bin/${TARGET}:\$PATH\""
echo "  $ROOT/bin/${TARGET}/bgdc.exe game.prg && $ROOT/bin/${TARGET}/bgdi.exe game.dcb"
