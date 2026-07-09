# PATH
export PATH="$HOME/.local/bin:$PATH"

# 기본 에디터
export EDITOR=nvim
export VISUAL=nvim

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
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^E^E' edit-command-line    # Ctrl+E Ctrl+E → 현재 명령어를 nvim에서 편집
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
autoload -Uz compinit
ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump"
if [ -s "$ZSH_COMPDUMP" ]; then
  compinit -C -d "$ZSH_COMPDUMP"
else
  compinit -d "$ZSH_COMPDUMP"
fi
unset ZSH_COMPDUMP
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# alias
if command -v eza &>/dev/null; then
  alias ls='eza'
  alias ll='eza -alF --git'
  alias la='eza -a'
  alias l='eza -F'
  alias lt='eza --tree'
else
  alias ls='ls --color=auto'
  alias ll='ls -alF'
  alias la='ls -A'
  alias l='ls -CF'
fi
alias grep='grep --color=auto'
if command -v nvim &>/dev/null; then
  alias vi='nvim'
  alias vim='nvim'
fi
if command -v lazygit &>/dev/null; then
  alias lg='lazygit'
fi

t() {
  local session="${1:-main}"
  tmux new -A -s "$session"
}

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
if command -v fd &>/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
if command -v bat &>/dev/null; then
  export FZF_DEFAULT_OPTS="--preview 'bat --color=always --line-range :100 {}'"
fi
if command -v fzf &>/dev/null; then
  if fzf --zsh &>/dev/null; then
    source <(fzf --zsh) 2>/dev/null
  else
    # 구버전 fzf 호환
    [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
    [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
  fi
fi

# 플러그인
ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
[ -f "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -f "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# starship 프롬프트
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# dotfiles 자동 동기화 (하루 1회 백그라운드 pull + restow)
# source된 파일 위치에서 dotfiles git 루트 자동 감지
__DOTFILES_SOURCE="${${(%):-%x}:A}"
__DOTFILES_DIR="${__DOTFILES_SOURCE:h}"
while [ "$__DOTFILES_DIR" != "/" ] && [ ! -d "$__DOTFILES_DIR/.git" ]; do
  __DOTFILES_DIR="${__DOTFILES_DIR:h}"
done
unset __DOTFILES_SOURCE
__DOTFILES_LAST_PULL="$HOME/.cache/dotfiles-last-pull"
__DOTFILES_LAST_ATTEMPT="$HOME/.cache/dotfiles-last-attempt"
__DOTFILES_LOG="$HOME/.cache/dotfiles-update.log"

__dotfiles_log() {
  mkdir -p "$(dirname "$__DOTFILES_LOG")"
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$__DOTFILES_LOG"
}

dotfiles-update() {
  if [ ! -d "$__DOTFILES_DIR/.git" ]; then
    echo "dotfiles 디렉토리가 없거나 git 저장소가 아닙니다: $__DOTFILES_DIR"
    __dotfiles_log "manual: not a git repo: $__DOTFILES_DIR"
    return 1
  fi
  echo "dotfiles pull 중..."
  if ! git -C "$__DOTFILES_DIR" pull --ff-only; then
    echo "pull 실패 — 로컬 변경/충돌 또는 네트워크 확인"
    __dotfiles_log "manual: pull failed"
    return 1
  fi
  if command -v stow &>/dev/null; then
    if ! stow --dir="$__DOTFILES_DIR" --target="$HOME" --restow .; then
      __dotfiles_log "manual: stow failed"
      return 1
    fi
  fi
  mkdir -p "$(dirname "$__DOTFILES_LAST_PULL")"
  date +%s > "$__DOTFILES_LAST_PULL"
  __dotfiles_log "manual: updated"
  echo "완료. 새 셸 열거나 'source ~/.zshrc'로 적용."
}

if [ -d "$__DOTFILES_DIR/.git" ]; then
  __now=$(date +%s)
  __last=$(cat "$__DOTFILES_LAST_PULL" 2>/dev/null || echo 0)
  __last_attempt=$(cat "$__DOTFILES_LAST_ATTEMPT" 2>/dev/null || echo 0)
  if [ $((__now - __last)) -gt 86400 ] && [ $((__now - __last_attempt)) -gt 3600 ]; then
    mkdir -p "$(dirname "$__DOTFILES_LAST_ATTEMPT")"
    echo "$__now" > "$__DOTFILES_LAST_ATTEMPT"
    {
      # 로컬 변경 있으면 충돌 위험으로 스킵
      if [ -z "$(git -C "$__DOTFILES_DIR" status --porcelain 2>/dev/null)" ]; then
        if git -C "$__DOTFILES_DIR" pull --ff-only --quiet 2>/dev/null; then
          if command -v stow &>/dev/null; then
            if stow --dir="$__DOTFILES_DIR" --target="$HOME" --restow . &>/dev/null; then
              date +%s > "$__DOTFILES_LAST_PULL"
              __dotfiles_log "auto: updated"
            else
              __dotfiles_log "auto: stow failed"
            fi
          else
            date +%s > "$__DOTFILES_LAST_PULL"
            __dotfiles_log "auto: pulled, stow missing"
          fi
        else
          __dotfiles_log "auto: pull failed"
        fi
      else
        __dotfiles_log "auto: skipped, local changes"
      fi
    } &!
  fi
  unset __now __last __last_attempt
fi

# zoxide (스마트 cd)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# 터미널 리사이즈 시 prompt 강제 재갱신 (줄바꿈 깨짐 방지)
TRAPWINCH() {
  COLUMNS=$(tput cols)
  LINES=$(tput lines)
  zle && zle reset-prompt
}

# 로컬 전용 설정 (git에 올라가지 않음)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
