# dotfiles

## Linux / macOS / WSL

사전 준비: `git`, `nvim`

```bash
git clone git@github.com:dornol/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

## Windows

WSL 터미널에서 실행:

```bash
powershell.exe -ExecutionPolicy Bypass -File "$(wslpath -w ~/dotfiles/install.ps1)"
```

`.gitconfig`, `.claude/settings.json`, `.claude/hooks/notify.sh` 적용됨 (MCP 설정은 유지)

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

## 민감한 환경변수

`~/.zshrc.local` 파일에 추가 (git 제외):

```bash
export CLAUDE_SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
```
