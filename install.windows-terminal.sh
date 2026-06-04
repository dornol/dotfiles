#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS1_WIN="$(wslpath -w "$SCRIPT_DIR/install.windows-terminal.ps1")"

powershell.exe -ExecutionPolicy Bypass -File "$PS1_WIN" "$@"
