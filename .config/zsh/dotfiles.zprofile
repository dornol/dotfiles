# Login-shell-only initialization belongs here.
[[ -n "${INTELLIJ_ENVIRONMENT_READER:-}" ]] && return
[[ -n "${__DOTFILES_IJENT_ENV_READER:-}" ]] && return
[[ -r "$HOME/.zprofile.local" ]] && source "$HOME/.zprofile.local"
