#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS1_WIN="$(wslpath -w "$SCRIPT_DIR/install-windows-terminal.ps1")"

powershell.exe -ExecutionPolicy Bypass -File "$PS1_WIN" "$@" | iconv -f cp949 -t utf-8 2>/dev/null
