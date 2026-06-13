# Windows Terminal theme and font installer
param(
  [switch]$FontsOnly,
  [switch]$ThemesOnly
)

$ErrorActionPreference = 'Stop'

function Find-WTSettingsAll {
  @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
  ) | Where-Object { Test-Path $_ }
}

function Get-LatestTag($repo) {
  (Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest" `
    -Headers @{'User-Agent' = 'dotfiles'} -UseBasicParsing).tag_name
}

function Test-FontInstalled($fileName) {
  (Test-Path "$env:SystemRoot\Fonts\$fileName") -or
  (Test-Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\$fileName")
}

function Install-FontFile($path) {
  $shell = New-Object -ComObject Shell.Application
  $shell.Namespace(0x14).CopyHere($path, 0x14)
}

function Install-FontsFromZip($url, $label, $exactName) {
  Write-Host "  Downloading $label..."
  $zip = [IO.Path]::GetTempFileName() + '.zip'
  $dir = [IO.Path]::Combine([IO.Path]::GetTempPath(), [IO.Path]::GetRandomFileName())
  try {
    Invoke-WebRequest $url -OutFile $zip -UseBasicParsing
    Expand-Archive $zip $dir -Force
    $fonts = Get-ChildItem $dir -Recurse -Include '*.ttf', '*.otf' |
             Where-Object { $_.Name -eq $exactName }
    $fonts | ForEach-Object { Install-FontFile $_.FullName }
    Write-Host "  $label done"
  }
  finally {
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# -- Font -------------------------------------------------------------------
if (-not $ThemesOnly) {
  Write-Host "Installing font..."
  $fontFile = 'JetBrainsMonoNerdFont-Regular.ttf'
  if (Test-FontInstalled $fontFile) {
    Write-Host "  JetBrains Mono Nerd Font already installed, skipping"
  }
  else {
    $nfTag = Get-LatestTag 'ryanoasis/nerd-fonts'
    Install-FontsFromZip `
      "https://github.com/ryanoasis/nerd-fonts/releases/download/$nfTag/JetBrainsMono.zip" `
      'JetBrains Mono Nerd Font' `
      $fontFile
  }
  Write-Host "Font done`n"
}

# -- Theme ------------------------------------------------------------------
if (-not $FontsOnly) {
  $settingsFiles = Find-WTSettingsAll
  if (-not $settingsFiles -or $settingsFiles.Count -eq 0) {
    Write-Warning "Windows Terminal settings not found. Run Windows Terminal once and try again."
  }
  else {
    $scheme = [PSCustomObject]@{
      name                = 'GitHub Light'
      background          = '#FFFFFF'; foreground          = '#24292E'
      cursorColor         = '#044289'; selectionBackground = '#000000'
      black               = '#24292E'; brightBlack         = '#959DA5'
      red                 = '#D73A49'; brightRed           = '#CB2431'
      green               = '#22863A'; brightGreen         = '#28A745'
      yellow              = '#B08800'; brightYellow        = '#DBAB09'
      blue                = '#0366D6'; brightBlue          = '#2188FF'
      purple              = '#6F42C1'; brightPurple        = '#8A63D2'
      cyan                = '#1B7C83'; brightCyan          = '#3192AA'
      white               = '#6A737D'; brightWhite         = '#D1D5DA'
    }

    foreach ($settings in $settingsFiles) {
      Write-Host "Installing theme... ($settings)"

      $backup = "$settings.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
      Copy-Item $settings $backup
      Write-Host "Backup: $(Split-Path $backup -Leaf)"

      $json = Get-Content $settings -Raw | ConvertFrom-Json

      if (-not ($json.PSObject.Properties.Name -contains 'schemes')) {
        $json | Add-Member -MemberType NoteProperty -Name 'schemes' -Value @()
      }

      $json.schemes = @($json.schemes | Where-Object { $_.name -ne $scheme.name }) + $scheme
      Write-Host "  GitHub Light"

      if (-not ($json.PSObject.Properties.Name -contains 'profiles')) {
        $json | Add-Member -MemberType NoteProperty -Name 'profiles' -Value ([PSCustomObject]@{})
      }
      if (-not ($json.profiles.PSObject.Properties.Name -contains 'defaults')) {
        $json.profiles | Add-Member -MemberType NoteProperty -Name 'defaults' -Value ([PSCustomObject]@{})
      }
      $json.profiles.defaults | Add-Member -MemberType NoteProperty -Name 'colorScheme' -Value 'GitHub Light' -Force
      $json.profiles.defaults | Add-Member -MemberType NoteProperty -Name 'font' `
        -Value ([PSCustomObject]@{ face = 'JetBrainsMono Nerd Font' }) -Force

      if ($json.profiles.PSObject.Properties.Name -contains 'list') {
        foreach ($profile in $json.profiles.list) {
          $profile | Add-Member -MemberType NoteProperty -Name 'colorScheme' -Value 'GitHub Light' -Force
        }
      }
      Write-Host "  Default profile: GitHub Light + JetBrainsMono Nerd Font"

      $json | ConvertTo-Json -Depth 10 | Set-Content $settings -Encoding UTF8
      Write-Host "Theme done"
    }
  }
}

Write-Host "`nDone! Restart Windows Terminal to apply."
