#!/usr/bin/env bash
set -e

FONTS_ONLY=false
THEMES_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --fonts-only|-FontsOnly) FONTS_ONLY=true ;;
    --themes-only|-ThemesOnly) THEMES_ONLY=true ;;
    -h|--help)
      cat <<EOF
사용법: bash install.macos-terminal.sh [--fonts-only|--themes-only]

macOS Terminal과 WezTerm에 GitHub Light 테마와
JetBrains Mono Nerd Font를 적용합니다.
EOF
      exit 0
      ;;
    *) echo "알 수 없는 옵션: $arg"; exit 1 ;;
  esac
done

if [ "$FONTS_ONLY" = true ] && [ "$THEMES_ONLY" = true ]; then
  echo "--fonts-only와 --themes-only는 함께 사용할 수 없습니다."
  exit 1
fi

if [ "$(uname -s)" != "Darwin" ]; then
  echo "이 스크립트는 macOS 전용입니다."
  exit 1
fi

if ! command -v brew &>/dev/null; then
  echo "Homebrew가 필요합니다. 먼저 install.sh를 실행하세요."
  exit 1
fi

install_font() {
  echo "JetBrains Mono Nerd Font 확인 중..."
  if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
    echo "  이미 설치됨"
  else
    brew install --cask font-jetbrains-mono-nerd-font
  fi
}

install_wezterm() {
  if [ ! -d /Applications/WezTerm.app ] && [ ! -d "$HOME/Applications/WezTerm.app" ]; then
    echo "WezTerm 설치 중..."
    brew install --cask wezterm
  fi
}

install_terminal_profile() {
  echo "macOS Terminal 프로필 적용 중..."
  profile_dir="$(mktemp -d "${TMPDIR:-/tmp}/github-light.XXXXXX")"
  profile_file="$profile_dir/GitHub Light.terminal"
  trap 'rm -rf "$profile_dir"' EXIT

  PROFILE_FILE="$profile_file" osascript -l JavaScript >/dev/null <<'JXA'
ObjC.import("AppKit");
ObjC.import("Foundation");

function archive(object) {
  return $.NSKeyedArchiver.archivedDataWithRootObject(object);
}

function color(hex) {
  var value = parseInt(hex.slice(1), 16);
  return $.NSColor.colorWithSRGBRedGreenBlueAlpha(
    ((value >> 16) & 255) / 255,
    ((value >> 8) & 255) / 255,
    (value & 255) / 255,
    1
  );
}

var font = $.NSFont.fontWithNameSize($("JetBrainsMono Nerd Font"), 13);
if (!font) {
  throw new Error("JetBrains Mono Nerd Font를 찾을 수 없습니다.");
}

var profile = $.NSMutableDictionary.alloc.init;
var colors = {
  BackgroundColor: "#FFFFFF",
  TextColor: "#24292E",
  TextBoldColor: "#24292E",
  CursorColor: "#044289",
  SelectionColor: "#0366D6",
  ANSIBlackColor: "#24292E",
  ANSIRedColor: "#D73A49",
  ANSIGreenColor: "#22863A",
  ANSIYellowColor: "#B08800",
  ANSIBlueColor: "#0366D6",
  ANSIMagentaColor: "#6F42C1",
  ANSICyanColor: "#1B7C83",
  ANSIWhiteColor: "#6A737D",
  ANSIBrightBlackColor: "#959DA5",
  ANSIBrightRedColor: "#CB2431",
  ANSIBrightGreenColor: "#28A745",
  ANSIBrightYellowColor: "#DBAB09",
  ANSIBrightBlueColor: "#2188FF",
  ANSIBrightMagentaColor: "#8A63D2",
  ANSIBrightCyanColor: "#3192AA",
  ANSIBrightWhiteColor: "#D1D5DA",
};

Object.keys(colors).forEach(function (key) {
  profile.setObjectForKey(archive(color(colors[key])), $(key));
});
profile.setObjectForKey(archive(font), $("Font"));
profile.setObjectForKey(true, $("FontAntialias"));
profile.setObjectForKey(true, $("UseBoldFonts"));
profile.setObjectForKey(false, $("DynamicANSIForegroundColors"));
profile.setObjectForKey(0, $("BackgroundBlur"));
profile.setObjectForKey($("2.09"), $("ProfileCurrentVersion"));
profile.setObjectForKey($("GitHub Light"), $("name"));
profile.setObjectForKey($("Window Settings"), $("type"));
var profileFile = $.NSProcessInfo.processInfo.environment.objectForKey(
  $("PROFILE_FILE")
);
profile.writeToFileAtomically(profileFile, true);
JXA

  profile_xml="$(plutil -convert xml1 -o - "$profile_file")"
  defaults write com.apple.Terminal "Window Settings" \
    -dict-add "GitHub Light" "$profile_xml"
  defaults write com.apple.Terminal "Default Window Settings" -string "GitHub Light"
  defaults write com.apple.Terminal "Startup Window Settings" -string "GitHub Light"

  echo "  GitHub Light + JetBrains Mono Nerd Font 적용됨"
  if pgrep -x Terminal &>/dev/null; then
    echo "  Terminal을 완전히 종료한 뒤 다시 열면 적용됨"
  fi
}

if [ "$THEMES_ONLY" = false ]; then
  install_font
fi

if [ "$FONTS_ONLY" = false ]; then
  install_wezterm
  install_terminal_profile
  echo "  WezTerm 설정은 ~/.wezterm.lua에서 적용됨"
fi

echo "완료! Terminal과 WezTerm을 다시 열어 주세요."
