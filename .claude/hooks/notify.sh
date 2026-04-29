#!/bin/bash
INPUT=$(cat)
OS="$(uname -s)"

# JSON 파싱
if command -v jq &>/dev/null; then
  MESSAGE=$(echo "$INPUT" | jq -r '.message // "Needs your attention"')
  PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // ""')
elif command -v python3 &>/dev/null; then
  MESSAGE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','Needs your attention'))")
  PROJECT_DIR=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cwd',''))")
else
  MESSAGE="Needs your attention"
  PROJECT_DIR=""
fi

PROJECT_NAME=$(basename "$PROJECT_DIR" 2>/dev/null || echo "unknown")

# OS별 데스크탑 알림
case "$OS" in
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      # WSL — Windows 토스트
      powershell.exe -NoProfile -Command "
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > \$null
        \$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
        \$textNodes = \$template.GetElementsByTagName('text')
        \$textNodes.Item(0).AppendChild(\$template.CreateTextNode('Claude Code — $PROJECT_NAME')) > \$null
        \$textNodes.Item(1).AppendChild(\$template.CreateTextNode('$MESSAGE')) > \$null
        \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$template)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$toast)
      " 2>/dev/null &
    elif command -v notify-send &>/dev/null; then
      notify-send "Claude Code — $PROJECT_NAME" "$MESSAGE" &
    fi
    ;;
  Darwin)
    osascript -e "display notification \"$MESSAGE\" with title \"Claude Code — $PROJECT_NAME\"" &
    ;;
esac

# Slack 알림 (CLAUDE_SLACK_WEBHOOK_URL 환경변수 필요)
if [ -n "$CLAUDE_SLACK_WEBHOOK_URL" ]; then
  PAYLOAD="{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\":robot_face:  *${PROJECT_NAME}*\n${MESSAGE}\"}}]}"
  curl -s -X POST "$CLAUDE_SLACK_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d "$PAYLOAD" > /dev/null 2>&1 &
fi
