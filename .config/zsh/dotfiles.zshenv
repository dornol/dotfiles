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
