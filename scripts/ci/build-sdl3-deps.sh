#!/usr/bin/env bash
# Build SDL3 + SDL3_mixer into a prefix for Autotools pkg-config consumers.
# System zlib/libpng/openssl come from the OS packages.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEPS_DIR="${DEPS_DIR:-$ROOT/.deps}"
PREFIX="${PREFIX:-$DEPS_DIR/prefix}"
SRC_DIR="${SRC_DIR:-$DEPS_DIR/src}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"

SDL3_REF="${SDL3_REF:-release-3.4.14}"
SDL3_MIXER_REF="${SDL3_MIXER_REF:-release-3.2.4}"
BUILD_TYPE="${BUILD_TYPE:-Release}"

mkdir -p "$SRC_DIR" "$PREFIX"

fetch_git() {
  local url="$1"
  local ref="$2"
  local dest="$3"
  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" fetch --depth 1 origin "$ref" || true
    git -C "$dest" fetch --depth 1 origin "refs/tags/${ref}:refs/tags/${ref}" || true
    git -C "$dest" checkout -f "$ref"
  else
    rm -rf "$dest"
    if ! git clone --depth 1 --branch "$ref" "$url" "$dest"; then
      git clone --depth 1 "$url" "$dest"
      git -C "$dest" fetch --depth 1 origin "refs/tags/${ref}:refs/tags/${ref}" || \
        git -C "$dest" fetch --depth 1 origin "$ref"
      git -C "$dest" checkout -f "$ref"
    fi
  fi
}

cmake_configure() {
  local src="$1"
  local build="$2"
  shift 2
  cmake -S "$src" -B "$build" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -G Ninja \
    "$@"
}

cmake_build_install() {
  local build="$1"
  cmake --build "$build" --config "$BUILD_TYPE" -j"$JOBS"
  cmake --install "$build" --config "$BUILD_TYPE"
}

echo "==> SDL3 deps prefix: $PREFIX"

echo "==> [1/2] SDL3 ${SDL3_REF}"
rm -rf "$SRC_DIR/SDL-build"
fetch_git "https://github.com/libsdl-org/SDL.git" "$SDL3_REF" "$SRC_DIR/SDL"
cmake_configure "$SRC_DIR/SDL" "$SRC_DIR/SDL-build" \
  -DSDL_SHARED=ON \
  -DSDL_STATIC=OFF \
  -DSDL_TEST_LIBRARY=OFF \
  -DSDL_TESTS=OFF \
  -DSDL_INSTALL_DOCS=OFF
cmake_build_install "$SRC_DIR/SDL-build"

echo "==> [2/2] SDL3_mixer ${SDL3_MIXER_REF}"
rm -rf "$SRC_DIR/SDL_mixer-build"
fetch_git "https://github.com/libsdl-org/SDL_mixer.git" "$SDL3_MIXER_REF" "$SRC_DIR/SDL_mixer"
cmake_configure "$SRC_DIR/SDL_mixer" "$SRC_DIR/SDL_mixer-build" \
  -DBUILD_SHARED_LIBS=ON \
  -DSDLMIXER_DEPS_SHARED=ON \
  -DSDLMIXER_VENDORED=OFF \
  -DSDLMIXER_EXAMPLES=OFF \
  -DSDLMIXER_TESTS=OFF \
  -DSDLMIXER_STRICT=OFF \
  -DSDLMIXER_GME=OFF \
  -DSDLMIXER_MOD=OFF \
  -DSDLMIXER_MIDI=OFF \
  -DSDLMIXER_WAVPACK=OFF \
  -DSDLMIXER_FLAC=OFF \
  -DSDLMIXER_OPUS=OFF \
  -DSDLMIXER_MP3=ON \
  -DSDLMIXER_MP3_DRMP3=ON \
  -DSDLMIXER_MP3_MPG123=OFF \
  -DSDLMIXER_VORBIS_STB=ON \
  -DSDLMIXER_VORBIS_VORBISFILE=OFF \
  -DSDLMIXER_VORBIS_TREMOR=OFF
cmake_build_install "$SRC_DIR/SDL_mixer-build"

# Help Autotools find the packages
HOST_OS="$(uname -s)"
{
  echo "export PREFIX=\"$PREFIX\""
  echo "export PKG_CONFIG_PATH=\"$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig\${PKG_CONFIG_PATH:+:\$PKG_CONFIG_PATH}\""
  echo "export PATH=\"$PREFIX/bin:\$PATH\""
  if [[ "$HOST_OS" == "Darwin" ]]; then
    echo "export DYLD_LIBRARY_PATH=\"$PREFIX/lib:$PREFIX/lib64\${DYLD_LIBRARY_PATH:+:\$DYLD_LIBRARY_PATH}\""
    # Homebrew OpenSSL / libpng for Autotools AC_CHECK_LIB / pkg-config.
    if command -v brew >/dev/null 2>&1; then
      for f in openssl@3 libpng zlib; do
        pref="$(brew --prefix "$f" 2>/dev/null || true)"
        if [[ -n "$pref" && -d "$pref/lib/pkgconfig" ]]; then
          echo "export PKG_CONFIG_PATH=\"$pref/lib/pkgconfig:\$PKG_CONFIG_PATH\""
        fi
        if [[ -n "$pref" && -d "$pref/lib" ]]; then
          echo "export LDFLAGS=\"-L$pref/lib \${LDFLAGS:-}\""
          echo "export CPPFLAGS=\"-I$pref/include \${CPPFLAGS:-}\""
          echo "export DYLD_LIBRARY_PATH=\"$pref/lib:\${DYLD_LIBRARY_PATH:-}\""
        fi
      done
    fi
  elif [[ "$HOST_OS" == MINGW* || "$HOST_OS" == MSYS* || "$HOST_OS" == CYGWIN* || -n "${MSYSTEM:-}" ]]; then
    # MinGW loads shared SDL3 from PATH (DLLs under prefix/bin).
    echo "export PATH=\"$PREFIX/bin:\${MSYSTEM_PREFIX:-/ucrt64}/bin:\$PATH\""
    if [[ -n "${MSYSTEM_PREFIX:-}" && -d "$MSYSTEM_PREFIX/lib/pkgconfig" ]]; then
      echo "export PKG_CONFIG_PATH=\"$MSYSTEM_PREFIX/lib/pkgconfig:\$PKG_CONFIG_PATH\""
    fi
  else
    echo "export LD_LIBRARY_PATH=\"$PREFIX/lib:$PREFIX/lib64\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}\""
  fi
} > "$DEPS_DIR/env.sh"

echo "==> Wrote $DEPS_DIR/env.sh"
# shellcheck disable=SC1091
source "$DEPS_DIR/env.sh"
pkg-config --exists --print-errors sdl3
pkg-config --exists --print-errors sdl3-mixer
pkg-config --modversion sdl3
pkg-config --modversion sdl3-mixer
echo "SDL3 deps ready."
