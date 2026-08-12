[![CI](https://github.com/humbertodias/BennuGD/actions/workflows/ci.yml/badge.svg)](https://github.com/humbertodias/BennuGD/actions/workflows/ci.yml)
![GitHub all releases](https://img.shields.io/github/downloads/humbertodias/BennuGD/total)

# BennuGD

Classic [BennuGD](https://www.bennugd.org/) runtime (`bgdc` / `bgdi` + modules), maintained for modern 64-bit hosts with **SDL3**.

CI publishes native builds for:

- Linux x86_64
- Windows x86_64 (MinGW-w64 UCRT64)
- macOS arm64

## Install

Linux / macOS / Git Bash:

```shell
curl -sL "https://raw.githubusercontent.com/humbertodias/BennuGD/main/scripts/install.sh" | bash
```

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/humbertodias/BennuGD/main/scripts/install.ps1 | iex
```

This installs `bgdc` (compiler) and `bgdi` (interpreter) under `$HOME/bennugd` (`%USERPROFILE%\bennugd` on Windows) and updates your `PATH`.

Optional overrides:

| Variable | Meaning |
|----------|---------|
| `BENNUGD_HOME` | Install directory |
| `BENNUGD_VERSION` | Release tag (default: latest) |
| `BENNUGD_REPO` | GitHub `owner/name` (default: `humbertodias/BennuGD`) |

## Getting started

- Docs: [BennuGD documentation](https://divhub.github.io/bennugd-website/docs/)
- Assets: [FPG Editor](https://github.com/humbertodias/fpg-editor/)

Quick check after install:

```shell
bgdc -help
bgdi -help
```

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

## Related

- [BennuGD64](https://github.com/humbertodias/BennuGD64) — CMake fork with static modules
