#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
ARCH="$(uname -m)"

PURGE=false
for arg in "$@"; do
  case "$arg" in
    --purge) PURGE=true ;;
    -h|--help)
      cat <<EOF
사용법: bash uninstall.sh [--purge]

기본:    stow 링크 해제 + .bashrc의 zsh 자동 전환 라인 제거 + 백업 복원
--purge: 추가로 install.sh가 직접 설치한 도구 제거
         (zsh 플러그인, starship, fzf, delta, fnm, nvim, ruff)
         패키지 매니저로 설치된 stow/zsh/tmux/pipx는 건드리지 않음
EOF
      exit 0
      ;;
    *) echo "알 수 없는 옵션: $arg"; exit 1 ;;
  esac
done

# stow 링크 해제
if command -v stow &>/dev/null; then
  echo "dotfiles 링크 해제 중..."
  stow --dir="$DOTFILES_DIR" --target="$HOME" --delete . || true
fi

# .bashrc에서 zsh 자동 전환 라인 제거
if grep -q 'exec zsh' "$HOME/.bashrc" 2>/dev/null; then
  echo ".bashrc에서 zsh 자동 전환 라인 제거 중..."
  grep -v 'exec zsh' "$HOME/.bashrc" > /tmp/.bashrc_tmp || true
  mv /tmp/.bashrc_tmp "$HOME/.bashrc"
fi

# 가장 최신 .bak.* 백업을 원래 위치로 복원
restore_latest_backup() {
  local target="$1"
  local latest
  latest=$(ls -1dt "${target}.bak."* 2>/dev/null | head -n 1 || true)
  if [ -n "$latest" ]; then
    if [ -e "$target" ] || [ -L "$target" ]; then
      rm -rf "$target"
    fi
    echo "백업 복원: $latest -> $target"
    mv "$latest" "$target"
  fi
}

restore_latest_backup "$HOME/.config/nvim"
restore_latest_backup "$HOME/.wezterm.lua"
restore_latest_backup "$HOME/.gitconfig"
restore_latest_backup "$HOME/.zshrc"
restore_latest_backup "$HOME/.tmux.conf"
restore_latest_backup "$HOME/.claude/settings.json"
restore_latest_backup "$HOME/.claude/hooks/notify.sh"

if [ "$PURGE" = true ]; then
  echo "설치한 도구 제거 중..."

  # zsh 플러그인
  rm -rf "$HOME/.zsh/plugins/zsh-autosuggestions"
  rm -rf "$HOME/.zsh/plugins/zsh-syntax-highlighting"
  [ -d "$HOME/.zsh/plugins" ] && rmdir "$HOME/.zsh/plugins" 2>/dev/null || true
  [ -d "$HOME/.zsh" ] && rmdir "$HOME/.zsh" 2>/dev/null || true

  # starship (curl 설치는 기본 /usr/local/bin)
  if [ -x /usr/local/bin/starship ]; then
    sudo rm -f /usr/local/bin/starship
  fi

  # fzf, delta, fnm (~/.local/bin)
  rm -f "$HOME/.local/bin/fzf"
  rm -f "$HOME/.local/bin/delta"
  rm -f "$HOME/.local/bin/fnm"
  rm -rf "$HOME/.local/share/fnm"

  # nvim (Linux에서 GitHub 릴리즈로 직접 설치한 경우만)
  case "$OS" in
    Linux)
      NVIM_ARCH=$([ "$ARCH" = "aarch64" ] && echo "arm64" || echo "x86_64")
      if [ -d "/opt/nvim-linux-${NVIM_ARCH}" ]; then
        sudo rm -rf "/opt/nvim-linux-${NVIM_ARCH}"
      fi
      if [ -L /usr/local/bin/nvim ]; then
        sudo rm -f /usr/local/bin/nvim
      fi
      ;;
  esac

  # ruff (pipx)
  if command -v pipx &>/dev/null; then
    pipx uninstall ruff 2>/dev/null || true
  fi

  echo "참고: 패키지 매니저로 설치된 stow/zsh/tmux/pipx는 그대로 둠. 필요하면 직접 제거하세요."
fi

echo "완료!"
