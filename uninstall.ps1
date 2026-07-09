# dotfiles uninstaller for Windows
$DOTFILES = Split-Path -Parent $MyInvocation.MyCommand.Path
$HOME_DIR = $env:USERPROFILE

function Remove-JsonObjectProperties {
  param(
    [Parameter(Mandatory = $true)]$Target,
    [Parameter(Mandatory = $true)]$Source
  )

  foreach ($property in $Source.PSObject.Properties) {
    $name = $property.Name
    if (-not ($Target.PSObject.Properties.Name -contains $name)) {
      continue
    }

    $targetValue = $Target.$name
    $sourceValue = $property.Value
    if (($targetValue -is [pscustomobject]) -and ($sourceValue -is [pscustomobject])) {
      Remove-JsonObjectProperties -Target $targetValue -Source $sourceValue
      if ($targetValue.PSObject.Properties.Count -eq 0) {
        $Target.PSObject.Properties.Remove($name)
      }
    } else {
      $Target.PSObject.Properties.Remove($name)
    }
  }
}

function Restore-LatestBackup {
  param([string]$Target)
  $parent = Split-Path $Target -Parent
  $leaf = Split-Path $Target -Leaf
  if (-not (Test-Path $parent)) { return }
  $backups = Get-ChildItem -Path $parent -Filter "$leaf.bak.*" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending
  if ($backups -and $backups.Count -gt 0) {
    if (Test-Path $Target) {
      Remove-Item $Target -Recurse -Force
    }
    Move-Item $backups[0].FullName $Target
    Write-Host "Backup restored: $($backups[0].Name) -> $Target"
  }
}

# .gitconfig: dotfiles 사본 제거 후 백업 복원
$gitconfig = "$HOME_DIR\.gitconfig"
if (Test-Path $gitconfig) {
  Remove-Item $gitconfig -Force
  Write-Host ".gitconfig removed"
}
Restore-LatestBackup -Target $gitconfig

# .claude/settings.json: dotfiles에서 머지된 키만 제거
$targetSettings = "$HOME_DIR\.claude\settings.json"
$sourceSettings = "$DOTFILES\.claude\settings.json"
if ((Test-Path $targetSettings) -and (Test-Path $sourceSettings)) {
  $dotfilesJson = Get-Content $sourceSettings -Raw | ConvertFrom-Json
  $existingJson = Get-Content $targetSettings -Raw | ConvertFrom-Json
  Remove-JsonObjectProperties -Target $existingJson -Source $dotfilesJson
  if ($existingJson.PSObject.Properties.Count -eq 0) {
    Remove-Item $targetSettings -Force
    Write-Host ".claude/settings.json removed (empty after key removal)"
  } else {
    $existingJson | ConvertTo-Json -Depth 10 | Set-Content $targetSettings
    Write-Host ".claude/settings.json: dotfiles keys removed"
  }
}

# .claude/hooks/notify.sh
$notifyHook = "$HOME_DIR\.claude\hooks\notify.sh"
if (Test-Path $notifyHook) {
  Remove-Item $notifyHook -Force
  Write-Host ".claude/hooks/notify.sh removed"
}

Write-Host "All done!"
