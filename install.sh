#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 의존성 확인
deps_ok=true
for cmd in git nvim; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "필요한 프로그램이 없습니다: $cmd"
    deps_ok=false
  fi
done
[ "$deps_ok" = false ] && exit 1

if ! command -v stow &>/dev/null; then
  echo "stow이 설치되어 있지 않습니다. 설치 중..."
  sudo apt-get install -y stow
fi

# 기존 ~/.config/nvim이 심볼릭 링크가 아닌 실제 디렉토리면 백업 후 제거
NVIM_CONFIG="$HOME/.config/nvim"
if [ -d "$NVIM_CONFIG" ] && [ ! -L "$NVIM_CONFIG" ]; then
  BACKUP="$HOME/.config/nvim.bak.$(date +%Y%m%d%H%M%S)"
  echo "기존 nvim 설정 백업 중... ($NVIM_CONFIG -> $BACKUP)"
  mv "$NVIM_CONFIG" "$BACKUP"
fi

echo "dotfiles 링크 중... ($DOTFILES_DIR -> $HOME)"
stow --dir="$DOTFILES_DIR" --target="$HOME" .

echo "완료!"
