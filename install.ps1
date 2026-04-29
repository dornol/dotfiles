# Windows용 dotfiles 설치 스크립트
$DOTFILES = Split-Path -Parent $MyInvocation.MyCommand.Path
$HOME_DIR = $env:USERPROFILE

function Backup-IfExists($target) {
  if ((Test-Path $target) -and (-not (Get-Item $target).LinkType)) {
    $backup = "$target.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Write-Host "백업 중... ($target -> $backup)"
    Move-Item $target $backup
  }
}

# .gitconfig 복사
Backup-IfExists "$HOME_DIR\.gitconfig"
Copy-Item "$DOTFILES\.gitconfig" "$HOME_DIR\.gitconfig"
Write-Host ".gitconfig 적용 완료"

# .claude/settings.json 복사
$claudeDir = "$HOME_DIR\.claude"
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir | Out-Null }
Backup-IfExists "$claudeDir\settings.json"
Copy-Item "$DOTFILES\.claude\settings.json" "$claudeDir\settings.json"
Write-Host ".claude/settings.json 적용 완료"

# .claude/hooks 복사
$hooksDir = "$claudeDir\hooks"
if (-not (Test-Path $hooksDir)) { New-Item -ItemType Directory -Path $hooksDir | Out-Null }
Copy-Item "$DOTFILES\.claude\hooks\notify.sh" "$hooksDir\notify.sh" -Force
Write-Host ".claude/hooks/notify.sh 적용 완료"

Write-Host "완료!"
