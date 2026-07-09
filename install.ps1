# dotfiles installer for Windows
$DOTFILES = Split-Path -Parent $MyInvocation.MyCommand.Path
$HOME_DIR = $env:USERPROFILE

function Test-SameFileContent {
  param(
    [Parameter(Mandatory = $true)][string]$First,
    [Parameter(Mandatory = $true)][string]$Second
  )

  if ((-not (Test-Path $First)) -or (-not (Test-Path $Second))) {
    return $false
  }

  $firstHash = (Get-FileHash -Algorithm SHA256 $First).Hash
  $secondHash = (Get-FileHash -Algorithm SHA256 $Second).Hash
  return $firstHash -eq $secondHash
}

function Merge-JsonObject {
  param(
    [Parameter(Mandatory = $true)]$Target,
    [Parameter(Mandatory = $true)]$Source
  )

  foreach ($property in $Source.PSObject.Properties) {
    $name = $property.Name
    $value = $property.Value

    if ($Target.PSObject.Properties.Name -contains $name) {
      $targetValue = $Target.$name
      if (($targetValue -is [pscustomobject]) -and ($value -is [pscustomobject])) {
        Merge-JsonObject -Target $targetValue -Source $value | Out-Null
      } else {
        $Target | Add-Member -MemberType NoteProperty -Name $name -Value $value -Force
      }
    } else {
      $Target | Add-Member -MemberType NoteProperty -Name $name -Value $value
    }
  }

  return $Target
}

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
  Merge-JsonObject -Target $existingJson -Source $dotfilesJson | Out-Null
  $existingJson | ConvertTo-Json -Depth 10 | Set-Content $targetSettings
  Write-Host ".claude/settings.json merged"
} else {
  Copy-Item $sourceSettings $targetSettings
  Write-Host ".claude/settings.json done"
}

# .claude/hooks
$hooksDir = "$claudeDir\hooks"
if (-not (Test-Path $hooksDir)) { New-Item -ItemType Directory -Path $hooksDir | Out-Null }
$sourceHook = "$DOTFILES\.claude\hooks\notify.sh"
$targetHook = "$hooksDir\notify.sh"
if ((Test-Path $targetHook) -and (-not (Test-SameFileContent -First $targetHook -Second $sourceHook))) {
  $backup = "$targetHook.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
  Write-Host "Backing up... ($targetHook -> $backup)"
  Move-Item $targetHook $backup
}
Copy-Item $sourceHook $targetHook -Force
Write-Host ".claude/hooks/notify.sh done"

Write-Host "All done!"
