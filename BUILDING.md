## Build from source

Dependencies: Autotools, pkg-config, CMake/Ninja (to build SDL3), zlib, libpng, OpenSSL.

```shell
# Build SDL3 + SDL3_mixer into .deps/
./scripts/ci/build-sdl3-deps.sh
source .deps/env.sh

# Native build (pick your OS)
./build-linux-native.sh release    # Linux
./build-macos-native.sh release    # macOS
./build-windows-native.sh release  # MSYS2 UCRT64
```

Binaries land in `bin/<triplet>/` (for example `bin/x86_64-linux-gnu/`).

Smoke / package helpers used by CI:

```shell
./scripts/ci/smoke.sh
./scripts/ci/package.sh
```
