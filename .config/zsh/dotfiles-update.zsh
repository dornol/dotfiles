# Explicit update command: shell startup performs no git/network/file writes.
typeset -g __DOTFILES_DIR="${${(%):-%x}:A:h:h:h}"
typeset -g __DOTFILES_LOG="$HOME/.cache/dotfiles-update.log"

__dotfiles_log() {
  mkdir -p "${__DOTFILES_LOG:h}"
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$__DOTFILES_LOG"
}

dotfiles-update() {
  if [[ ! -d "$__DOTFILES_DIR/.git" ]]; then
    print -u2 "dotfiles 디렉토리가 git 저장소가 아닙니다: $__DOTFILES_DIR"
    return 1
  fi
  print "dotfiles pull 중..."
  if ! git -C "$__DOTFILES_DIR" pull --ff-only; then
    print -u2 "pull 실패 — 로컬 변경/충돌 또는 네트워크 확인"
    __dotfiles_log "manual: pull failed"
    return 1
  fi
  if [[ -x "$__DOTFILES_DIR/bin/dotfiles-apply" ]] &&
     ! bash "$__DOTFILES_DIR/bin/dotfiles-apply"; then
    __dotfiles_log "manual: apply failed"
    return 1
  fi
  __dotfiles_log "manual: updated"
  print "완료. 새 셸을 열거나 'source ~/.zshrc'로 적용하세요."
}
