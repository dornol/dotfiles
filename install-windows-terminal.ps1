# Windows Terminal 테마 및 폰트 설치
param(
  [switch]$FontsOnly,
  [switch]$ThemesOnly
)

$ErrorActionPreference = 'Stop'

function Find-WTSettings {
  @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
  ) | Where-Object { Test-Path $_ } | Select-Object -First 1
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
  Write-Host "  $label 다운로드 중..."
  $zip = [IO.Path]::GetTempFileName() + '.zip'
  $dir = [IO.Path]::Combine([IO.Path]::GetTempPath(), [IO.Path]::GetRandomFileName())
  try {
    Invoke-WebRequest $url -OutFile $zip -UseBasicParsing
    Expand-Archive $zip $dir -Force
    $fonts = Get-ChildItem $dir -Recurse -Include '*.ttf', '*.otf' |
             Where-Object { $_.Name -eq $exactName }
    $fonts | ForEach-Object { Install-FontFile $_.FullName }
    Write-Host "  $label 완료"
  }
  finally {
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# ── 테마 설치 ────────────────────────────────────────────────────────────
if (-not $FontsOnly) {
  $settings = Find-WTSettings
  if (-not $settings) {
    Write-Warning "Windows Terminal 설정 파일 없음. Windows Terminal을 한 번 실행한 뒤 다시 시도하세요."
  }
  else {
    Write-Host "테마 설치 중... ($settings)"

    $backup = "$settings.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item $settings $backup
    Write-Host "백업: $(Split-Path $backup -Leaf)"

    $json = Get-Content $settings -Raw | ConvertFrom-Json

    if (-not ($json.PSObject.Properties.Name -contains 'schemes')) {
      $json | Add-Member -MemberType NoteProperty -Name 'schemes' -Value @()
    }

    $scheme = [PSCustomObject]@{
      name                = 'GitHub Light'
      background          = '#FFFFFF'; foreground          = '#24292E'
      cursorColor         = '#044289'; selectionBackground = '#0366D6'
      black               = '#24292E'; brightBlack         = '#959DA5'
      red                 = '#D73A49'; brightRed           = '#CB2431'
      green               = '#22863A'; brightGreen         = '#28A745'
      yellow              = '#B08800'; brightYellow        = '#DBAB09'
      blue                = '#0366D6'; brightBlue          = '#2188FF'
      purple              = '#6F42C1'; brightPurple        = '#8A63D2'
      cyan                = '#1B7C83'; brightCyan          = '#3192AA'
      white               = '#6A737D'; brightWhite         = '#D1D5DA'
    }

    $json.schemes = @($json.schemes | Where-Object { $_.name -ne $scheme.name }) + $scheme
    Write-Host "  GitHub Light"

    # profiles.defaults — 색 구성표 + 폰트 기본값 설정
    if (-not ($json.PSObject.Properties.Name -contains 'profiles')) {
      $json | Add-Member -MemberType NoteProperty -Name 'profiles' -Value ([PSCustomObject]@{})
    }
    if (-not ($json.profiles.PSObject.Properties.Name -contains 'defaults')) {
      $json.profiles | Add-Member -MemberType NoteProperty -Name 'defaults' -Value ([PSCustomObject]@{})
    }
    $json.profiles.defaults | Add-Member -MemberType NoteProperty -Name 'colorScheme' -Value 'GitHub Light' -Force
    $json.profiles.defaults | Add-Member -MemberType NoteProperty -Name 'font' `
      -Value ([PSCustomObject]@{ face = 'JetBrainsMono Nerd Font' }) -Force
    Write-Host "  기본값 설정 (GitHub Light + JetBrainsMono Nerd Font)"

    $json | ConvertTo-Json -Depth 10 | Set-Content $settings -Encoding UTF8
    Write-Host "테마 완료"
  }
}

# ── 폰트 설치 ────────────────────────────────────────────────────────────
if (-not $ThemesOnly) {
  Write-Host "`n폰트 설치 중..."
  $fontFile = 'JetBrainsMonoNerdFont-Regular.ttf'
  if (Test-FontInstalled $fontFile) {
    Write-Host "  JetBrains Mono Nerd Font 이미 설치됨, 스킵"
  }
  else {
    $nfTag = Get-LatestTag 'ryanoasis/nerd-fonts'
    Install-FontsFromZip `
      "https://github.com/ryanoasis/nerd-fonts/releases/download/$nfTag/JetBrainsMono.zip" `
      'JetBrains Mono Nerd Font' `
      $fontFile
  }
  Write-Host "폰트 완료"
}

Write-Host "`n완료! Windows Terminal을 재시작하면 적용됩니다."
