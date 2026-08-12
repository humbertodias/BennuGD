[![CI](https://github.com/humbertodias/BennuGD/actions/workflows/ci.yml/badge.svg)](https://github.com/humbertodias/BennuGD/actions/workflows/ci.yml)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/humbertodias/BennuGD)
![GitHub all releases](https://img.shields.io/github/downloads/humbertodias/BennuGD/total)

# BennuGD

[BennuGD](https://www.bennugd.org/) compiler and runtime (`bgdc` / `bgdi` + modules) for modern 64-bit hosts (SDL3). Keeps the classic language ABI (4-byte `INT`/`POINTER`) so existing BGD1 programs keep working.

Related: [BennuGD64](https://github.com/humbertodias/BennuGD64) — same goal with CMake and statically linked modules.

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

Enjoy!
