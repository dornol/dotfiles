# dotfiles

## Linux / macOS / WSL

사전 준비: `git`, `nvim`

```bash
git clone git@github.com:dornol/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

macOS에서는 다음 설정도 자동 적용됨.

- macOS Terminal / WezTerm 테마: GitHub Light
- 폰트: JetBrains Mono Nerd Font (Regular)
- WezTerm이 없으면 Homebrew로 자동 설치
- WezTerm 설정: `~/.wezterm.lua`

macOS 터미널 설정만 개별 실행:

```bash
bash ~/dotfiles/install.macos-terminal.sh --themes-only  # 테마만
bash ~/dotfiles/install.macos-terminal.sh --fonts-only   # 폰트만
```

## Windows

WSL 터미널에서 실행:

```bash
powershell.exe -ExecutionPolicy Bypass -File "$(wslpath -w ~/dotfiles/install.ps1)"
```

`.gitconfig`, `.claude/settings.json`, `.claude/hooks/notify.sh` 적용됨 (MCP 설정은 유지)

WSL에서 `install.sh` 실행 시 Windows Terminal 테마/폰트도 자동 적용됨.

- 테마: GitHub Light
- 폰트: JetBrains Mono Nerd Font (Regular)
- 기본 프로파일에 자동 적용

SSH 설정과 키는 변경하지 않으며 Windows와 WSL에서 각각 관리함.

개별 실행이 필요한 경우:

```bash
bash ~/dotfiles/install.windows-terminal.sh -ThemesOnly  # 테마만
bash ~/dotfiles/install.windows-terminal.sh -FontsOnly   # 폰트만
```

## Uninstall

Linux / macOS / WSL:

```bash
bash ~/dotfiles/uninstall.sh           # 링크 해제 + 백업 복원
bash ~/dotfiles/uninstall.sh --purge   # 추가로 설치한 도구 제거
```

Windows:

```bash
powershell.exe -ExecutionPolicy Bypass -File "$(wslpath -w ~/dotfiles/uninstall.ps1)"
```

## 자동 동기화

새 zsh 셸을 열 때마다 마지막 pull로부터 24시간 이상 지났으면 백그라운드로
`git pull` + `stow --restow`를 자동 실행. 로컬에 커밋되지 않은 변경이 있으면
충돌 방지를 위해 스킵. 즉시 받고 싶으면:

```bash
dotfiles-update
```

dotfiles 디렉토리는 `.zshrc` 심볼릭 링크를 따라 자동 감지되므로
설치 경로가 `~/dotfiles`가 아니어도 동작.

## 민감한 환경변수

`~/.zshrc.local` 파일에 추가 (git 제외):

```bash
export CLAUDE_SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
```
