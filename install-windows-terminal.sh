#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS1_WIN="$(wslpath -w "$SCRIPT_DIR/install-windows-terminal.ps1")"

# chcp 65001로 UTF-8 코드페이지 설정 후 실행 (한글 깨짐 방지)
ARGS=""
for arg in "$@"; do ARGS="$ARGS $arg"; done

powershell.exe -ExecutionPolicy Bypass -Command "chcp 65001 | Out-Null; & '$PS1_WIN'$ARGS"
