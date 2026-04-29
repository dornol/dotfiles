# dotfiles installer for Windows
$DOTFILES = Split-Path -Parent $MyInvocation.MyCommand.Path
$HOME_DIR = $env:USERPROFILE

# .gitconfig
$gitconfig = "$HOME_DIR\.gitconfig"
if ((Test-Path $gitconfig) -and (-not (Get-Item $gitconfig).LinkType)) {
  $backup = "$gitconfig.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
  Write-Host "Backing up... ($gitconfig -> $backup)"
  Move-Item $gitconfig $backup
}
Copy-Item "$DOTFILES\.gitconfig" $gitconfig
Write-Host ".gitconfig done"

# .claude/settings.json (merge)
$claudeDir = "$HOME_DIR\.claude"
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir | Out-Null }

$targetSettings = "$claudeDir\settings.json"
$sourceSettings = "$DOTFILES\.claude\settings.json"
$dotfilesJson = Get-Content $sourceSettings -Raw | ConvertFrom-Json

if (Test-Path $targetSettings) {
  $existingJson = Get-Content $targetSettings -Raw | ConvertFrom-Json
  foreach ($key in $dotfilesJson.PSObject.Properties.Name) {
    $existingJson | Add-Member -MemberType NoteProperty -Name $key -Value $dotfilesJson.$key -Force
  }
  $existingJson | ConvertTo-Json -Depth 10 | Set-Content $targetSettings
  Write-Host ".claude/settings.json merged"
} else {
  Copy-Item $sourceSettings $targetSettings
  Write-Host ".claude/settings.json done"
}

# .claude/hooks
$hooksDir = "$claudeDir\hooks"
if (-not (Test-Path $hooksDir)) { New-Item -ItemType Directory -Path $hooksDir | Out-Null }
Copy-Item "$DOTFILES\.claude\hooks\notify.sh" "$hooksDir\notify.sh" -Force
Write-Host ".claude/hooks/notify.sh done"

Write-Host "All done!"
