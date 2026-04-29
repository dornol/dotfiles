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

## 민감한 환경변수

`~/.zshrc.local` 파일에 추가 (git 제외):

```bash
export CLAUDE_SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
```
