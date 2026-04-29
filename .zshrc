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

# fzf
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
fi

# 플러그인
ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# starship 프롬프트
eval "$(starship init zsh)"
