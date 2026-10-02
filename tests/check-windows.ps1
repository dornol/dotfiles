$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$temporary = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
$previousProfile = $env:USERPROFILE
function Assert-True($condition, $message) {
  if (-not $condition) { throw $message }
}
try {
  New-Item -ItemType Directory -Path "$temporary\.claude" -Force | Out-Null
  $env:USERPROFILE = $temporary
  $gitconfig = "$temporary\.gitconfig"
  $originalGit = "[user]`n name = Machine User`n[core]`n pager = less`n"
  [IO.File]::WriteAllText($gitconfig, $originalGit)
  $settings = "$temporary\.claude\settings.json"
  [IO.File]::WriteAllText($settings, '{"language":"english","custom":true,"hooks":{"Notification":[{"custom":true}]}}')
  New-Item -ItemType Directory -Path "$temporary\.claude\hooks" | Out-Null
  $hook = "$temporary\.claude\hooks\notify.sh"
  [IO.File]::WriteAllText($hook, '# original user hook')
  & "$repo\install.ps1"
  $firstGit = Get-Content $gitconfig -Raw
  $firstSettings = Get-Content $settings -Raw
  & "$repo\install.ps1"
  Assert-True ((Get-Content $gitconfig -Raw) -eq $firstGit) 'Git include is not idempotent'
  Assert-True ((Get-Content $settings -Raw) -eq $firstSettings) 'Settings merge is not idempotent'
  $merged = Get-Content $settings -Raw | ConvertFrom-Json
  Assert-True ($merged.language -eq 'english') 'User language overwritten'
  Assert-True ($merged.hooks.Notification.Count -eq 2) 'Custom notification hook lost or duplicated'
  # git -f tests the wrapper independently of the runner account's HOME.
  $name = git config --file $gitconfig --includes --get user.name
  Assert-True ($name -eq 'Machine User') 'Machine Git setting overridden'
  & "$repo\uninstall.ps1" -Purge
  Assert-True ((Get-Content $gitconfig -Raw) -eq $originalGit) 'Uninstall modified user Git settings'
  $remaining = Get-Content $settings -Raw | ConvertFrom-Json
  Assert-True ($remaining.language -eq 'english') 'Purge deleted edited language'
  Assert-True ($remaining.hooks.Notification.Count -eq 1) 'Purge deleted custom hook'
  Assert-True ($remaining.hooks.Notification[0].custom -eq $true) 'Custom hook changed'
  Assert-True ((Get-Content $hook -Raw) -eq '# original user hook') 'Original hook backup was not restored'
  & "$repo\uninstall.ps1" -Purge
  # Repeat the lifecycle for an initially empty profile as well.
  $env:USERPROFILE = "$temporary\fresh"
  New-Item -ItemType Directory -Path $env:USERPROFILE | Out-Null
  & "$repo\install.ps1"
  & "$repo\install.ps1"
  & "$repo\uninstall.ps1" -Purge
  & "$repo\uninstall.ps1" -Purge
  Write-Host 'Windows install/reapply/purge checks passed'
} finally {
  $env:USERPROFILE = $previousProfile
  Remove-Item $temporary -Recurse -Force -ErrorAction SilentlyContinue
}
