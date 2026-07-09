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
TITLE="Claude Code — $PROJECT_NAME"

json_escape() {
  if command -v jq &>/dev/null; then
    jq -Rn --arg value "$1" '$value'
  elif command -v python3 &>/dev/null; then
    VALUE="$1" python3 -c 'import json, os; print(json.dumps(os.environ["VALUE"]))'
  else
    printf '"%s"' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  fi
}

# OS별 데스크탑 알림
case "$OS" in
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      # WSL — Windows 토스트
      CLAUDE_NOTIFY_TITLE="$TITLE" CLAUDE_NOTIFY_MESSAGE="$MESSAGE" powershell.exe -NoProfile -Command "
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > \$null
        \$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
        \$textNodes = \$template.GetElementsByTagName('text')
        \$textNodes.Item(0).AppendChild(\$template.CreateTextNode(\$env:CLAUDE_NOTIFY_TITLE)) > \$null
        \$textNodes.Item(1).AppendChild(\$template.CreateTextNode(\$env:CLAUDE_NOTIFY_MESSAGE)) > \$null
        \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$template)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$toast)
      " 2>/dev/null &
    elif command -v notify-send &>/dev/null; then
      notify-send "$TITLE" "$MESSAGE" &
    fi
    ;;
  Darwin)
    osascript - "$TITLE" "$MESSAGE" <<'APPLESCRIPT' &
on run argv
  display notification (item 2 of argv) with title (item 1 of argv)
end run
APPLESCRIPT
    ;;
esac

# Slack 알림 (CLAUDE_SLACK_WEBHOOK_URL 환경변수 필요)
if [ -n "$CLAUDE_SLACK_WEBHOOK_URL" ]; then
  SLACK_TEXT=":robot_face:  *${PROJECT_NAME}*
${MESSAGE}"
  PAYLOAD='{"blocks":[{"type":"section","text":{"type":"mrkdwn","text":'"$(json_escape "$SLACK_TEXT")"'}}]}'
  curl -s -X POST "$CLAUDE_SLACK_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d "$PAYLOAD" > /dev/null 2>&1 &
fi
