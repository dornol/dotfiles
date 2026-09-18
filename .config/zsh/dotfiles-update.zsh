# Explicit update command: shell startup performs no git/network/file writes.
typeset -g __DOTFILES_DIR="${${(%):-%x}:A:h:h:h}"
typeset -g __DOTFILES_LOG="$HOME/.cache/dotfiles-update.log"
typeset -g __DOTFILES_AUTO_UPDATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"

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

dotfiles-update-plugins() {
  local plugin_dir="$HOME/.zsh/plugins"
  local plugin
  local failed=0

  for plugin in "$plugin_dir"/*; do
    [[ -d "$plugin/.git" ]] || continue
    print "플러그인 업데이트 중: ${plugin:t}"
    if ! git -C "$plugin" pull --ff-only; then
      print -u2 "업데이트 실패: ${plugin:t}"
      failed=1
    fi
  done

  if (( failed )); then
    __dotfiles_log "manual: plugin update failed"
    return 1
  fi

  __dotfiles_log "manual: plugins updated"
  print "플러그인 업데이트 완료. 새 셸을 열거나 'source ~/.zshrc'로 적용하세요."
}

dotfiles-auto-update() {
  (( $+commands[git] )) || return
  [[ -n "${DOTFILES_AUTO_UPDATE_DISABLED:-}" ]] && return

  local stamp="$__DOTFILES_AUTO_UPDATE_DIR/last-attempt"
  local lock="$__DOTFILES_AUTO_UPDATE_DIR/lock"
  local last=0
  [[ -r "$stamp" ]] && read -r last < "$stamp"
  (( last > 0 && EPOCHSECONDS - last < 86400 )) && return

  mkdir -p "$__DOTFILES_AUTO_UPDATE_DIR" 2>/dev/null || return
  mkdir "$lock" 2>/dev/null || return
  print -r -- "$EPOCHSECONDS" > "$stamp" || {
    rmdir "$lock" 2>/dev/null
    return
  }

  (
    trap 'rmdir "$lock" 2>/dev/null' EXIT
    {
      print "자동 업데이트 시작: $__DOTFILES_DIR"
      if GIT_TERMINAL_PROMPT=0 git -C "$__DOTFILES_DIR" pull --ff-only; then
        if [[ -x "$__DOTFILES_DIR/bin/dotfiles-apply" ]] &&
           ! bash "$__DOTFILES_DIR/bin/dotfiles-apply"; then
          print -u2 "pull은 완료됐지만 설정 적용에 실패했습니다."
        else
          print "자동 업데이트 및 설정 적용 완료"
        fi
      else
        print -u2 "자동 업데이트 실패 — 수동으로 dotfiles-update를 실행하거나 로그를 확인하세요."
      fi
    } >> "$__DOTFILES_LOG" 2>&1
  ) &!
}
