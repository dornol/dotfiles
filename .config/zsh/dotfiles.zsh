# JetBrains shell environment readers allocate a pseudo-TTY, so a TTY check
# alone is insufficient. They need exports from .zshenv, but never terminal UI.
[[ -n "${INTELLIJ_ENVIRONMENT_READER:-}" ]] && return

# Other IDE environment probes and `zsh -c` stop before terminal setup/commands.
[[ -o interactive ]] || return
[[ -t 0 && -t 1 ]] || return

HISTSIZE=10000
HISTFILE="$HOME/.zsh_history"
SAVEHIST=$HISTSIZE
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^E^E' edit-command-line
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[OH' beginning-of-line
bindkey '^[OF' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# Initialize completion on the first Tab.
__dotfiles_init_completion() {
  autoload -Uz compinit
  local compdump="${ZDOTDIR:-$HOME}/.zcompdump"
  if [[ -s "$compdump" ]]; then
    compinit -C -d "$compdump" || return
  else
    compinit -d "$compdump" || return
  fi
  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
  bindkey '^I' expand-or-complete
  unfunction __dotfiles_init_completion
  zle expand-or-complete
}
zle -N __dotfiles_init_completion
bindkey '^I' __dotfiles_init_completion

if (( $+commands[eza] )); then
  alias ls='eza' ll='eza -alF --git' la='eza -a' l='eza -F' lt='eza --tree'
else
  alias ls='ls --color=auto' ll='ls -alF' la='ls -A' l='ls -CF'
fi
alias grep='grep --color=auto'
(( $+commands[nvim] )) && alias vi='nvim' vim='nvim'
(( $+commands[lazygit] )) && alias lg='lazygit'

t() {
  local session="${1:-main}"
  tmux new -A -s "$session"
}

alias d='docker' dps='docker ps' dpsa='docker ps -a' di='docker images'
alias dex='docker exec -it' dlogs='docker logs -f' drm='docker rm'
alias drmi='docker rmi' dstop='docker stop'
alias dc='docker compose' dcu='docker compose up -d' dcd='docker compose down'
alias dcl='docker compose logs -f' dcr='docker compose restart'

# Node is already on the static default-version PATH; fnm hooks load on demand.
__dotfiles_init_fnm() {
  (( $+commands[fnm] )) || return 1
  unfunction fnm 2>/dev/null
  eval "$(command fnm env --use-on-cd)"
}
fnm() {
  __dotfiles_init_fnm || return
  fnm "$@"
}
autoload -Uz add-zsh-hook add-zle-hook-widget
__dotfiles_fnm_chpwd() {
  local dir="$PWD"
  while [[ "$dir" != / ]]; do
    if [[ -r "$dir/.node-version" || -r "$dir/.nvmrc" ]]; then
      __dotfiles_init_fnm &&
        add-zsh-hook -d chpwd __dotfiles_fnm_chpwd
      return
    fi
    dir="${dir:h}"
  done
}
add-zsh-hook -d chpwd __dotfiles_fnm_chpwd 2>/dev/null
add-zsh-hook chpwd __dotfiles_fnm_chpwd

# chpwd does not fire when a terminal starts inside a Node project. Check the
# initial working directory once, when ZLE is first entered. The check itself
# uses only zsh file tests; fnm runs only if a version marker is found.
__dotfiles_fnm_initial_pwd() {
  add-zle-hook-widget -d zle-line-init __dotfiles_fnm_initial_pwd
  __dotfiles_fnm_chpwd
}
add-zle-hook-widget -d zle-line-init __dotfiles_fnm_initial_pwd 2>/dev/null
add-zle-hook-widget zle-line-init __dotfiles_fnm_initial_pwd

# SDKMAN is large; source it only on the first sdk call.
sdk() {
  unfunction sdk
  local init="${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh"
  [[ -s "$init" ]] || return 127
  source "$init"
  sdk "$@"
}

# Generate fzf shell integration only on first Ctrl-R/Ctrl-T.
if [[ -z "${__DOTFILES_FZF_LOADED:-}" ]]; then
  __dotfiles_init_fzf() {
    (( $+commands[fzf] )) || return 1
    local init
    if init="$(fzf --zsh 2>/dev/null)"; then
      source <(print -r -- "$init")
    else
      local legacy_dir=/usr/share/doc/fzf/examples
      [[ -r "$legacy_dir/key-bindings.zsh" ]] &&
        source "$legacy_dir/key-bindings.zsh"
      [[ -r "$legacy_dir/completion.zsh" ]] &&
        source "$legacy_dir/completion.zsh"
    fi
    typeset -g __DOTFILES_FZF_LOADED=1
    unfunction __dotfiles_init_fzf
  }
  __dotfiles_fzf_widget() {
    local key="$KEYS"
    __dotfiles_init_fzf || return
    zle -U "$key"
  }
  zle -N __dotfiles_fzf_widget
  bindkey '^R' __dotfiles_fzf_widget
  bindkey '^T' __dotfiles_fzf_widget
fi

(( $+commands[fd] )) && {
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
}
(( $+commands[bat] )) &&
  export FZF_DEFAULT_OPTS="--preview 'bat --color=always --line-range :100 {}'"

# Parse ZLE plugins when the line editor is first entered, after the prompt is
# already visible. Syntax highlighting remains last, as required by the plugin.
__dotfiles_load_zle_plugins() {
  add-zle-hook-widget -d zle-line-init __dotfiles_load_zle_plugins
  [[ -n "${__DOTFILES_ZLE_PLUGINS_LOADED:-}" ]] && return
  local plugin_dir="$HOME/.zsh/plugins"
  [[ -r "$plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
    source "$plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -r "$plugin_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] &&
    source "$plugin_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  typeset -g __DOTFILES_ZLE_PLUGINS_LOADED=1
}
add-zle-hook-widget -d zle-line-init __dotfiles_load_zle_plugins 2>/dev/null
add-zle-hook-widget zle-line-init __dotfiles_load_zle_plugins

source "${${(%):-%x}:A:h}/prompt.zsh"
source "${${(%):-%x}:A:h}/dotfiles-update.zsh"
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
