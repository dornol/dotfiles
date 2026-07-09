#!/usr/bin/env bash
set -e
set -o pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
ARCH="$(uname -m)"
IS_WSL=false
if [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=true
fi

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# git 확인 (필수)
if ! command -v git &>/dev/null; then
  echo "필요한 프로그램이 없습니다: git"
  exit 1
fi

# 패키지 매니저로 설치
pkg_install() {
  case "$OS" in
    Linux)
      if command -v apt-get &>/dev/null; then
        sudo apt-get install -y "$@"
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y "$@"
      elif command -v yum &>/dev/null; then
        sudo yum install -y "$@"
      else
        echo "지원하지 않는 패키지 매니저입니다."
        exit 1
      fi
      ;;
    Darwin) brew install "$@" ;;
  esac
}

github_latest_tag() {
  local repo="$1"
  local response
  local tag
  response=$(curl -fsSL -H 'User-Agent: dotfiles' "https://api.github.com/repos/$repo/releases/latest")
  tag=$(printf '%s\n' "$response" \
    | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1)
  if [ -z "$tag" ]; then
    echo "GitHub 릴리스 태그를 가져오지 못했습니다: $repo" >&2
    exit 1
  fi
  printf '%s\n' "$tag"
}

# macOS: Homebrew 확인
if [ "$OS" = "Darwin" ] && ! command -v brew &>/dev/null; then
  echo "Homebrew 설치 중..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# curl 확인
if ! command -v curl &>/dev/null; then
  echo "curl 설치 중..."
  pkg_install curl
fi

# stow 설치
if ! command -v stow &>/dev/null; then
  echo "stow 설치 중..."
  pkg_install stow
fi

# C 컴파일러 설치 (treesitter 파서 빌드용)
if ! command -v cc &>/dev/null && ! command -v gcc &>/dev/null; then
  echo "C 컴파일러 설치 중..."
  case "$OS" in
    Linux)
      if command -v apt-get &>/dev/null; then
        sudo apt-get install -y build-essential
      elif command -v dnf &>/dev/null; then
        sudo dnf groupinstall -y "Development Tools"
      elif command -v yum &>/dev/null; then
        sudo yum groupinstall -y "Development Tools"
      fi
      ;;
    Darwin)
      xcode-select -p &>/dev/null || xcode-select --install
      ;;
  esac
fi

# nvim 설치 (GitHub에서 최신 버전)
NVIM_INSTALLED=false
if command -v nvim &>/dev/null; then
  NVIM_INSTALLED=true
else
  echo "nvim 설치 중..."
  case "$OS" in
    Linux)
      NVIM_ARCH=$([ "$ARCH" = "aarch64" ] && echo "arm64" || echo "x86_64")
      GLIBC_VER=$(ldd --version 2>&1 | awk 'NR==1{print $NF}')
      GLIBC_MINOR=$(echo "$GLIBC_VER" | cut -d. -f2)
      if [ "${GLIBC_MINOR:-0}" -lt 29 ] 2>/dev/null; then
        echo "GLIBC $GLIBC_VER — nvim 최신 버전 미지원, 건너뜀"
      else
        curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz" | sudo tar -xz -C /opt
        sudo ln -sf "/opt/nvim-linux-${NVIM_ARCH}/bin/nvim" /usr/local/bin/nvim
        NVIM_INSTALLED=true
      fi
      ;;
    Darwin)
      brew install neovim
      NVIM_INSTALLED=true
      ;;
  esac
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
  curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
fi

# fzf 설치 (최신 버전 GitHub에서 직접)
if ! command -v fzf &>/dev/null; then
  echo "fzf 설치 중..."
  case "$OS" in
    Linux)
      FZF_VERSION=$(github_latest_tag junegunn/fzf)
      FZF_VER="${FZF_VERSION#v}"
      FZF_ARCH=$([ "$ARCH" = "aarch64" ] && echo "arm64" || echo "amd64")
      curl -fsSL "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VER}-linux_${FZF_ARCH}.tar.gz" | tar -xz -C ~/.local/bin
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
      DELTA_VERSION=$(github_latest_tag dandavison/delta)
      DELTA_VER="${DELTA_VERSION#v}"
      if [ "$ARCH" = "aarch64" ]; then
        DELTA_ARCH="aarch64"
        DELTA_LIBC="gnu"
      else
        DELTA_ARCH="x86_64"
        DELTA_LIBC="musl"
      fi
      DELTA_TRIPLE="${DELTA_ARCH}-unknown-linux-${DELTA_LIBC}"
      curl -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VER}-${DELTA_TRIPLE}.tar.gz" | tar -xz -C /tmp
      mv "/tmp/delta-${DELTA_VER}-${DELTA_TRIPLE}/delta" "$HOME/.local/bin/delta"
      rm -rf "/tmp/delta-${DELTA_VER}-${DELTA_TRIPLE}"
      ;;
    Darwin)
      brew install git-delta
      ;;
  esac
fi

# bat 설치
if ! command -v bat &>/dev/null; then
  echo "bat 설치 중..."
  case "$OS" in
    Linux)
      BAT_VERSION=$(github_latest_tag sharkdp/bat)
      BAT_VER="${BAT_VERSION#v}"
      BAT_ARCH=$([ "$ARCH" = "aarch64" ] && echo "aarch64" || echo "x86_64")
      curl -fsSL "https://github.com/sharkdp/bat/releases/download/${BAT_VERSION}/bat-${BAT_VERSION}-${BAT_ARCH}-unknown-linux-musl.tar.gz" | tar -xz -C /tmp
      mv "/tmp/bat-${BAT_VERSION}-${BAT_ARCH}-unknown-linux-musl/bat" "$HOME/.local/bin/bat"
      rm -rf "/tmp/bat-${BAT_VERSION}-${BAT_ARCH}-unknown-linux-musl"
      ;;
    Darwin)
      brew install bat
      ;;
  esac
fi

# fd 설치
if ! command -v fd &>/dev/null; then
  echo "fd 설치 중..."
  case "$OS" in
    Linux)
      FD_VERSION=$(github_latest_tag sharkdp/fd)
      FD_VER="${FD_VERSION#v}"
      FD_ARCH=$([ "$ARCH" = "aarch64" ] && echo "aarch64" || echo "x86_64")
      curl -fsSL "https://github.com/sharkdp/fd/releases/download/${FD_VERSION}/fd-${FD_VERSION}-${FD_ARCH}-unknown-linux-musl.tar.gz" | tar -xz -C /tmp
      mv "/tmp/fd-${FD_VERSION}-${FD_ARCH}-unknown-linux-musl/fd" "$HOME/.local/bin/fd"
      rm -rf "/tmp/fd-${FD_VERSION}-${FD_ARCH}-unknown-linux-musl"
      ;;
    Darwin)
      brew install fd
      ;;
  esac
fi

# ripgrep 설치
if ! command -v rg &>/dev/null; then
  echo "ripgrep 설치 중..."
  case "$OS" in
    Linux)
      RG_VERSION=$(github_latest_tag BurntSushi/ripgrep)
      if [ "$ARCH" = "aarch64" ]; then
        RG_ARCH="aarch64"
        RG_LIBC="gnu"
      else
        RG_ARCH="x86_64"
        RG_LIBC="musl"
      fi
      RG_TRIPLE="${RG_ARCH}-unknown-linux-${RG_LIBC}"
      curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-${RG_TRIPLE}.tar.gz" | tar -xz -C /tmp
      mv "/tmp/ripgrep-${RG_VERSION}-${RG_TRIPLE}/rg" "$HOME/.local/bin/rg"
      rm -rf "/tmp/ripgrep-${RG_VERSION}-${RG_TRIPLE}"
      ;;
    Darwin)
      brew install ripgrep
      ;;
  esac
fi

# eza 설치
if ! command -v eza &>/dev/null; then
  echo "eza 설치 중..."
  case "$OS" in
    Linux)
      EZA_VERSION=$(github_latest_tag eza-community/eza)
      EZA_LIBC=$([ "$ARCH" = "aarch64" ] && echo "gnu" || echo "musl")
      curl -fsSL "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_${ARCH}-unknown-linux-${EZA_LIBC}.tar.gz" | tar -xz -C /tmp
      mv "/tmp/eza" "$HOME/.local/bin/eza"
      ;;
    Darwin)
      brew install eza
      ;;
  esac
fi

# zoxide 설치
if ! command -v zoxide &>/dev/null; then
  echo "zoxide 설치 중..."
  case "$OS" in
    Linux)
      ZOXIDE_VERSION=$(github_latest_tag ajeetdsouza/zoxide)
      ZOXIDE_VER="${ZOXIDE_VERSION#v}"
      ZOXIDE_ARCH=$([ "$ARCH" = "aarch64" ] && echo "aarch64" || echo "x86_64")
      curl -fsSL "https://github.com/ajeetdsouza/zoxide/releases/download/${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VER}-${ZOXIDE_ARCH}-unknown-linux-musl.tar.gz" | tar -xz -C /tmp
      mv "/tmp/zoxide" "$HOME/.local/bin/zoxide"
      ;;
    Darwin)
      brew install zoxide
      ;;
  esac
fi

# lazygit 설치
if ! command -v lazygit &>/dev/null; then
  echo "lazygit 설치 중..."
  case "$OS" in
    Linux)
      LG_VERSION=$(github_latest_tag jesseduffield/lazygit)
      LG_VER="${LG_VERSION#v}"
      LG_ARCH=$([ "$ARCH" = "aarch64" ] && echo "arm64" || echo "x86_64")
      curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${LG_VERSION}/lazygit_${LG_VER}_Linux_${LG_ARCH}.tar.gz" | tar -xz -C /tmp
      mv "/tmp/lazygit" "$HOME/.local/bin/lazygit"
      ;;
    Darwin)
      brew install lazygit
      ;;
  esac
fi

# TPM + tmux-resurrect 설치
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "TPM 설치 중..."
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
if [ ! -d "$HOME/.tmux/plugins/tmux-resurrect" ]; then
  echo "tmux-resurrect 설치 중..."
  git clone --depth=1 https://github.com/tmux-plugins/tmux-resurrect "$HOME/.tmux/plugins/tmux-resurrect"
fi

# pipx + Python 도구 설치
if ! command -v pipx &>/dev/null; then
  echo "pipx 설치 중..."
  pkg_install pipx 2>/dev/null || pip3 install --user pipx 2>/dev/null || true
fi

if command -v pipx &>/dev/null; then
  for tool in ruff; do
    if ! command -v "$tool" &>/dev/null; then
      echo "$tool 설치 중..."
      pipx install "$tool" || true
    fi
  done
fi

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

# .bashrc에 zsh 자동 전환 추가 (인터랙티브 셸에서만)
BASHRC_LINE='[[ $- == *i* ]] && [ -x "$(which zsh)" ] && exec zsh -l'
if ! grep -q "exec zsh" "$HOME/.bashrc" 2>/dev/null; then
  echo "$BASHRC_LINE" >> "$HOME/.bashrc"
  echo "zsh 자동 전환을 .bashrc에 추가했습니다."
elif grep -q 'exec zsh' "$HOME/.bashrc" && ! grep -q '\$-' "$HOME/.bashrc"; then
  # 인터랙티브 체크 없는 구버전이면 교체 (BSD/GNU sed 호환)
  grep -v 'exec zsh' "$HOME/.bashrc" > /tmp/.bashrc_tmp || true
  echo "$BASHRC_LINE" >> /tmp/.bashrc_tmp
  mv /tmp/.bashrc_tmp "$HOME/.bashrc"
  echo "zsh 자동 전환 코드를 인터랙티브 전용으로 업데이트했습니다."
fi

# 기존 파일이 심볼릭 링크가 아닌 실제 파일/디렉토리면 백업 후 제거
# dotfiles 디렉토리 안의 파일은 건드리지 않음
backup_if_exists() {
  local target="$1"
  local real
  real=$(realpath "$target" 2>/dev/null || echo "")
  # dotfiles 디렉토리 안의 파일이면 스킵
  if [[ "$real" == "$DOTFILES_DIR"* ]]; then
    return
  fi
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    echo "백업 중... ($target -> $backup)"
    mv "$target" "$backup"
  fi
}

backup_if_exists "$HOME/.config/nvim"
backup_if_exists "$HOME/.wezterm.lua"
backup_if_exists "$HOME/.gitconfig"
backup_if_exists "$HOME/.tmux.conf"
backup_if_exists "$HOME/.claude/hooks/notify.sh"

echo "dotfiles 적용 중... ($DOTFILES_DIR -> $HOME)"
bash "$DOTFILES_DIR/bin/dotfiles-apply"

echo "완료! 터미널 재시작하면 zsh로 전환돼."
if [ "$NVIM_INSTALLED" = false ]; then
  echo "주의: nvim은 이 시스템(GLIBC 구버전)에서 지원되지 않아 건너뜀."
fi

# WSL이면 Windows Terminal 테마/폰트 자동 설치
if [ "$IS_WSL" = true ]; then
  echo "WSL 감지됨. Windows Terminal 설정 확인 중..."
  if command -v powershell.exe &>/dev/null; then
    echo "Windows Terminal 설정 중..."
    PS1_WIN="$(wslpath -w "$DOTFILES_DIR/install.windows-terminal.ps1")"
    powershell.exe -ExecutionPolicy Bypass -File "$PS1_WIN"
  else
    echo "powershell.exe를 찾지 못해 Windows Terminal 설정을 건너뜀."
  fi
fi

# macOS이면 Terminal/WezTerm 테마와 폰트 자동 설치
if [ "$OS" = "Darwin" ]; then
  echo "macOS Terminal/WezTerm 설정 중..."
  bash "$DOTFILES_DIR/install.macos-terminal.sh"
fi
