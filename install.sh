#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v stow &>/dev/null; then
  echo "stow이 설치되어 있지 않습니다. 설치 중..."
  sudo apt-get install -y stow
fi

echo "dotfiles 링크 중... ($DOTFILES_DIR -> $HOME)"
stow --dir="$DOTFILES_DIR" --target="$HOME" .

echo "완료!"
