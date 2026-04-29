# Windows용 dotfiles 설치 스크립트
$DOTFILES = Split-Path -Parent $MyInvocation.MyCommand.Path
$HOME_DIR = $env:USERPROFILE

# .gitconfig 복사
$gitconfig = "$HOME_DIR\.gitconfig"
if ((Test-Path $gitconfig) -and (-not (Get-Item $gitconfig).LinkType)) {
  $backup = "$gitconfig.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
  Write-Host "백업 중... ($gitconfig -> $backup)"
  Move-Item $gitconfig $backup
}
Copy-Item "$DOTFILES\.gitconfig" $gitconfig
Write-Host ".gitconfig 적용 완료"

# .claude/settings.json 병합 (기존 설정 유지 + dotfiles 값 덮어쓰기)
$claudeDir = "$HOME_DIR\.claude"
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir | Out-Null }

$targetSettings = "$claudeDir\settings.json"
$sourceSettings = "$DOTFILES\.claude\settings.json"
$dotfilesJson = Get-Content $sourceSettings -Raw | ConvertFrom-Json

if (Test-Path $targetSettings) {
  $existingJson = Get-Content $targetSettings -Raw | ConvertFrom-Json
  # dotfiles 값으로 기존 설정 덮어쓰기 (기존 키는 유지)
  foreach ($key in $dotfilesJson.PSObject.Properties.Name) {
    $existingJson | Add-Member -MemberType NoteProperty -Name $key -Value $dotfilesJson.$key -Force
  }
  $existingJson | ConvertTo-Json -Depth 10 | Set-Content $targetSettings
  Write-Host ".claude/settings.json 병합 완료"
} else {
  Copy-Item $sourceSettings $targetSettings
  Write-Host ".claude/settings.json 적용 완료"
}

# .claude/hooks 복사
$hooksDir = "$claudeDir\hooks"
if (-not (Test-Path $hooksDir)) { New-Item -ItemType Directory -Path $hooksDir | Out-Null }
Copy-Item "$DOTFILES\.claude\hooks\notify.sh" "$hooksDir\notify.sh" -Force
Write-Host ".claude/hooks/notify.sh 적용 완료"

Write-Host "완료!"
