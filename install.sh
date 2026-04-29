#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

# 의존성 확인
deps_ok=true
for cmd in git nvim; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "필요한 프로그램이 없습니다: $cmd"
    deps_ok=false
  fi
done
[ "$deps_ok" = false ] && exit 1

# 패키지 매니저로 설치
pkg_install() {
  case "$OS" in
    Linux)  sudo apt-get install -y "$@" ;;
    Darwin) brew install "$@" ;;
  esac
}

# macOS: Homebrew 확인
if [ "$OS" = "Darwin" ] && ! command -v brew &>/dev/null; then
  echo "Homebrew 설치 중..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# stow 설치
if ! command -v stow &>/dev/null; then
  echo "stow 설치 중..."
  pkg_install stow
fi

# zsh 설치
if ! command -v zsh &>/dev/null; then
  echo "zsh 설치 중..."
  pkg_install zsh
fi

# zsh 플러그인 설치
ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
mkdir -p "$ZSH_PLUGIN_DIR"

if [ ! -d "$ZSH_PLUGIN_DIR/zsh-autosuggestions" ]; then
  echo "zsh-autosuggestions 설치 중..."
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" ]; then
  echo "zsh-syntax-highlighting 설치 중..."
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
fi

# starship 설치
if ! command -v starship &>/dev/null; then
  echo "starship 설치 중..."
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi

# 기본 셸을 zsh로 변경
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "기본 셸을 zsh로 변경 중..."
  chsh -s "$(which zsh)"
fi

# 기존 ~/.config/nvim이 심볼릭 링크가 아닌 실제 디렉토리면 백업 후 제거
NVIM_CONFIG="$HOME/.config/nvim"
if [ -d "$NVIM_CONFIG" ] && [ ! -L "$NVIM_CONFIG" ]; then
  BACKUP="$HOME/.config/nvim.bak.$(date +%Y%m%d%H%M%S)"
  echo "기존 nvim 설정 백업 중... ($NVIM_CONFIG -> $BACKUP)"
  mv "$NVIM_CONFIG" "$BACKUP"
fi

echo "dotfiles 링크 중... ($DOTFILES_DIR -> $HOME)"
stow --dir="$DOTFILES_DIR" --target="$HOME" --restow .

echo "완료! 터미널 재시작하면 zsh로 전환돼."
