# PATH
export PATH="$HOME/.local/bin:$PATH"

case "$(uname -s)" in
  Linux)
    export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
    ;;
  Darwin)
    # macOS는 brew로 설치된 경로 사용
    export PATH="$PATH:/opt/homebrew/bin"
    ;;
esac

# 히스토리
HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# 키 바인딩
bindkey "^[[H"  beginning-of-line   # Home
bindkey "^[[F"  end-of-line         # End
bindkey "^[[1~" beginning-of-line   # Home (rxvt/일부 리눅스)
bindkey "^[[4~" end-of-line         # End  (rxvt/일부 리눅스)
bindkey "^[OH"  beginning-of-line   # Home (tmux/screen)
bindkey "^[OF"  end-of-line         # End  (tmux/screen)
bindkey "^[[3~" delete-char         # Delete
bindkey "^[[1;5C" forward-word      # Ctrl+Right
bindkey "^[[1;5D" backward-word     # Ctrl+Left

# 자동완성
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# alias
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
if command -v nvim &>/dev/null; then
  alias vi='nvim'
  alias vim='nvim'
fi

# docker alias
alias d='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlogs='docker logs -f'
alias drm='docker rm'
alias drmi='docker rmi'
alias dstop='docker stop'

# docker compose alias
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dcr='docker compose restart'

# fnm (Node.js)
if command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd)"
fi

# fzf
if command -v fzf &>/dev/null; then
  if fzf --zsh &>/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    # 구버전 fzf 호환
    [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
    [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
  fi
fi

# 플러그인
ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# starship 프롬프트
eval "$(starship init zsh)"

# dotfiles 자동 동기화 (하루 1회 백그라운드 pull + restow)
# .zshrc 심볼릭 링크를 따라가서 dotfiles 디렉토리 자동 감지
__DOTFILES_DIR="${${(%):-%x}:A:h}"
__DOTFILES_LAST_PULL="$HOME/.cache/dotfiles-last-pull"

dotfiles-update() {
  if [ ! -d "$__DOTFILES_DIR/.git" ]; then
    echo "dotfiles 디렉토리가 없거나 git 저장소가 아닙니다: $__DOTFILES_DIR"
    return 1
  fi
  echo "dotfiles pull 중..."
  if ! git -C "$__DOTFILES_DIR" pull --ff-only; then
    echo "pull 실패 — 로컬 변경/충돌 또는 네트워크 확인"
    return 1
  fi
  if command -v stow &>/dev/null; then
    stow --dir="$__DOTFILES_DIR" --target="$HOME" --restow .
  fi
  mkdir -p "$(dirname "$__DOTFILES_LAST_PULL")"
  date +%s > "$__DOTFILES_LAST_PULL"
  echo "완료. 새 셸 열거나 'source ~/.zshrc'로 적용."
}

if [ -d "$__DOTFILES_DIR/.git" ]; then
  __now=$(date +%s)
  __last=$(cat "$__DOTFILES_LAST_PULL" 2>/dev/null || echo 0)
  if [ $((__now - __last)) -gt 86400 ]; then
    mkdir -p "$(dirname "$__DOTFILES_LAST_PULL")"
    echo "$__now" > "$__DOTFILES_LAST_PULL"
    {
      # 로컬 변경 있으면 충돌 위험으로 스킵
      if [ -z "$(git -C "$__DOTFILES_DIR" status --porcelain 2>/dev/null)" ]; then
        git -C "$__DOTFILES_DIR" pull --ff-only --quiet 2>/dev/null \
          && command -v stow &>/dev/null \
          && stow --dir="$__DOTFILES_DIR" --target="$HOME" --restow . &>/dev/null
      fi
    } &!
  fi
  unset __now __last
fi

# 로컬 전용 설정 (git에 올라가지 않음)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
