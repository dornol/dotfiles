# Environment shared by every zsh, including IDEs and CI.
# Keep this file declarative: do not run commands or source tool initializers here.
export LANG="${LANG:-en_US.UTF-8}"
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"
export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"

# Do not invent a broken JAVA_HOME on hosts where SDKMAN is not installed.
if [[ -z "${JAVA_HOME:-}" && -d "$SDKMAN_DIR/candidates/java/current" ]]; then
  export JAVA_HOME="$SDKMAN_DIR/candidates/java/current"
fi

# Debian/Ubuntu's global zshrc honors this and otherwise runs compinit before
# our interactive/TTY guard. It is a shell control flag, not an export.
typeset -g skip_global_compinit=1

# IJent 2026.2 does not export INTELLIJ_ENVIRONMENT_READER. Detect its login
# environment shell at the earliest startup stage. `read` is a zsh builtin, so
# this performs no subprocess or external command execution.
if [[ "$PWD" == "${TMPDIR:-/tmp}"/tmp.* && -r "/proc/$PPID/comm" ]]; then
  IFS= read -r __dotfiles_parent_comm < "/proc/$PPID/comm"
  if [[ "$__dotfiles_parent_comm" == ijent ]]; then
    typeset -g __DOTFILES_IJENT_ENV_READER=1
  fi
  unset __dotfiles_parent_comm
fi

typeset -aU path
typeset -U PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/.local/share/fnm/aliases/default/bin"
  $path
)
[[ -n "${JAVA_HOME:-}" ]] && path=("$JAVA_HOME/bin" $path)
case "$OSTYPE" in
  darwin*) path+=(/opt/homebrew/bin) ;;
  linux*)  path+=(/opt/nvim-linux-x86_64/bin) ;;
esac
export PATH

# IntelliJ IDEA 2026.2's IJent WSL environment reader can leave its
# LoginInteractive zsh waiting at a prompt instead of sending the environment
# query. Returning from .zprofile/.zshrc is not enough because the shell then
# waits forever. All required exports are ready now, so terminate only this
# narrowly identified probe before it can block the IDE for 30 seconds.
if [[ -n "${__DOTFILES_IJENT_ENV_READER:-}" ]]; then
  unset __DOTFILES_IJENT_ENV_READER
  exit 0
fi
