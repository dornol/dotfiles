# dotfiles

## 사전 준비

- `git`
- `nvim`

## 설치

```bash
git clone git@github.com:dornol/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

## 민감한 환경변수

`~/.zshrc.local` 파일에 추가 (git 제외):

```bash
export CLAUDE_SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
```
