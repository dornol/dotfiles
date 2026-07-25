# Sourced only after the interactive + TTY guards in dotfiles.zsh.
if (( $+commands[starship] )) && [[ -z "${__DOTFILES_STARSHIP_LOADED:-}" ]]; then
  typeset -g __STARSHIP_INIT_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/starship-init.zsh"
  if [[ -r "$__STARSHIP_INIT_CACHE" &&
        "$__STARSHIP_INIT_CACHE" -nt "$commands[starship]" ]]; then
    source "$__STARSHIP_INIT_CACHE"
  else
    # Never create cache files during startup. The apply command refreshes it.
    eval "$(starship init zsh)"
  fi
  typeset -g __DOTFILES_STARSHIP_LOADED=1
fi

if [[ -z "${__DOTFILES_ZOXIDE_LOADED:-}" ]]; then
  __dotfiles_init_zoxide() {
    (( $+commands[zoxide] )) || return 1
    unfunction z zi 2>/dev/null
    eval "$(command zoxide init zsh)"
    typeset -g __DOTFILES_ZOXIDE_LOADED=1
  }
  z() {
    __dotfiles_init_zoxide || return
    z "$@"
  }
  zi() {
    __dotfiles_init_zoxide || return
    zi "$@"
  }
fi

TRAPWINCH() {
  COLUMNS=${COLUMNS:-80}
  LINES=${LINES:-24}
  zle && zle reset-prompt
}
