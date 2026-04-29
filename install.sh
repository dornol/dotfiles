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

# tmux 설치
if ! command -v tmux &>/dev/null; then
  echo "tmux 설치 중..."
  pkg_install tmux
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

# fzf 설치 (최신 버전 GitHub에서 직접)
if ! command -v fzf &>/dev/null; then
  echo "fzf 설치 중..."
  case "$OS" in
    Linux)
      FZF_VERSION=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep tag_name | cut -d'"' -f4)
      FZF_VER="${FZF_VERSION#v}"
      curl -sL "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VER}-linux_amd64.tar.gz" | tar -xz -C ~/.local/bin
      ;;
    Darwin)
      brew install fzf
      ;;
  esac
fi

# delta 설치
if ! command -v delta &>/dev/null; then
  echo "delta 설치 중..."
  case "$OS" in
    Linux)
      DELTA_VERSION=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | grep tag_name | cut -d'"' -f4)
      curl -sL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb" -o /tmp/delta.deb
      sudo dpkg -i /tmp/delta.deb
      rm /tmp/delta.deb
      ;;
    Darwin)
      brew install git-delta
      ;;
  esac
fi

# pipx + Python 도구 설치
if ! command -v pipx &>/dev/null; then
  echo "pipx 설치 중..."
  pkg_install pipx
fi

for tool in ruff; do
  if ! command -v "$tool" &>/dev/null; then
    echo "$tool 설치 중..."
    pipx install "$tool"
  fi
done

# fnm + Node.js LTS 설치
if ! command -v fnm &>/dev/null; then
  echo "fnm 설치 중..."
  pkg_install unzip
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir ~/.local/bin --skip-shell
fi

if command -v fnm &>/dev/null && ! fnm list | grep -q lts; then
  echo "Node.js LTS 설치 중..."
  fnm install --lts
  fnm default lts-latest
fi

# 기본 셸을 zsh로 변경
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "기본 셸을 zsh로 변경 중..."
  chsh -s "$(which zsh)" 2>/dev/null || {
    # chsh 실패 시 .bashrc에 zsh 자동 전환 추가
    if ! grep -q "exec zsh" "$HOME/.bashrc" 2>/dev/null; then
      echo '[ -x "$(which zsh)" ] && exec zsh -l' >> "$HOME/.bashrc"
      echo "zsh 자동 전환을 .bashrc에 추가했습니다."
    fi
  }
fi

# 기존 파일이 심볼릭 링크가 아닌 실제 파일/디렉토리면 백업 후 제거
backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    echo "백업 중... ($target -> $backup)"
    mv "$target" "$backup"
  fi
}

backup_if_exists "$HOME/.config/nvim"
backup_if_exists "$HOME/.gitconfig"
backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.tmux.conf"
backup_if_exists "$HOME/.claude/settings.json"
backup_if_exists "$HOME/.claude/hooks/notify.sh"

echo "dotfiles 링크 중... ($DOTFILES_DIR -> $HOME)"
stow --dir="$DOTFILES_DIR" --target="$HOME" --restow .

echo "완료! 터미널 재시작하면 zsh로 전환돼."
