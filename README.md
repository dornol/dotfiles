# dotfiles

## Linux / macOS / WSL

사전 준비: `git`, `curl`

```bash
git clone git@github.com:dornol/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

IntelliJ의 WSL/IJent 환경 수집까지 zsh 기준으로 동작시키려면 WSL에서 사용자
기본 셸도 zsh로 맞춥니다. 이 설정은 머신별 계정 설정이므로 필요할 때 한 번만
명시적 옵션으로 실행합니다:

```bash
bash ~/dotfiles/install.sh --set-default-shell
```

실행 후 WSL 터미널과 IntelliJ를 완전히 재시작합니다.

SDKMAN도 함께 설치되며, Java/Kotlin/Gradle 등의 SDK는 필요할 때 직접 설치함.
예: `sdk install java`

macOS에서는 다음 설정도 자동 적용됨.

- macOS Terminal / WezTerm 테마: GitHub Light
- 폰트: JetBrains Mono Nerd Font (Regular)
- WezTerm이 없으면 Homebrew로 자동 설치
- WezTerm 설정: `~/.wezterm.lua`

macOS 터미널 설정만 개별 실행:

```bash
bash ~/dotfiles/install.macos-terminal.sh --themes-only  # 테마만
bash ~/dotfiles/install.macos-terminal.sh --fonts-only   # 폰트만
```

## Windows

WSL 터미널에서 실행:

```bash
powershell.exe -ExecutionPolicy Bypass -File "$(wslpath -w ~/dotfiles/install.ps1)"
```

`.gitconfig`의 공통 설정과 `.claude/settings.json`, `.claude/hooks/notify.sh` 적용됨 (MCP 설정은 유지)

Git 설정은 `~/.gitconfig` 맨 앞에서 공통 설정을 include합니다. 뒤에 있는
기존 머신별 설정과 `~/.gitconfig.local`로 공통 값을 덮어쓸 수 있습니다.
`git config --global`과 `gh auth setup-git`가 추가하는 설정은 로컬 wrapper에
저장되므로 dotfiles 저장소가 자동 변경되지 않습니다. 실행 권한 추적을 끄려면
필요한 환경에서만 `git config --global core.fileMode false`를 실행하세요.

WSL에서 `install.sh` 실행 시 Windows Terminal 테마/폰트도 자동 적용됨.

- 테마: GitHub Light
- 폰트: JetBrains Mono Nerd Font (Regular)
- 기본 프로파일에 자동 적용

SSH 설정과 키는 변경하지 않으며 Windows와 WSL에서 각각 관리함.

개별 실행이 필요한 경우:

```bash
bash ~/dotfiles/install.windows-terminal.sh -ThemesOnly  # 테마만
bash ~/dotfiles/install.windows-terminal.sh -FontsOnly   # 폰트만
```

## Uninstall

Linux / macOS / WSL:

```bash
bash ~/dotfiles/uninstall.sh           # 링크 해제 + 백업 복원
bash ~/dotfiles/uninstall.sh --purge   # 추가로 설치한 도구 제거
```

Windows:

```bash
powershell.exe -ExecutionPolicy Bypass -File "$(wslpath -w ~/dotfiles/uninstall.ps1)"          # 기본 정리
powershell.exe -ExecutionPolicy Bypass -File "$(wslpath -w ~/dotfiles/uninstall.ps1)" -Purge   # Claude settings의 dotfiles key 제거
```

## 자동 동기화

셸 시작 시 첫 interactive Zsh가 하루에 한 번 백그라운드에서 dotfiles 저장소를
`git pull --ff-only`로 확인합니다. 셸 시작은 pull이 끝날 때까지 기다리지 않으며,
인증 프롬프트도 표시하지 않습니다. 자동 업데이트를 끄려면
`DOTFILES_AUTO_UPDATE_DISABLED=1`을 설정하세요. 수동 업데이트는 다음 명령으로
실행합니다:

```bash
dotfiles-update
dotfiles-update-plugins
```

`dotfiles-update`는 dotfiles 저장소만 갱신하고, `dotfiles-update-plugins`는
설치된 zsh 플러그인을 각각 fast-forward 방식으로 갱신합니다.

자동 업데이트의 시도 시각과 결과는 `~/.cache/dotfiles-update.log`와
`~/.cache/dotfiles/` 아래에 저장됩니다.

`~/.zshenv`, `~/.zprofile`, `~/.zshrc`에는 각각 dotfiles source block만
추가됩니다. `.zshenv`는 IDE/CI에도 필요한 환경변수만, `.zprofile`은 로그인 셸
설정만, `.zshrc`는 interactive TTY 설정만 로드합니다. 따라서 Go,
SDKMAN 같은 설치 도구가 `~/.zshrc`에 로컬 설정을 추가해도 repo는 변경되지 않음.

## 민감한 환경변수

`~/.zshrc.local`은 사람이 사용하는 interactive TTY에서만 읽힙니다. 터미널
전용 alias와 함수는 이 파일에 추가합니다:

```bash
alias work='cd ~/work'
```

로그인 셸에만 필요한 초기화는 `~/.zprofile.local`에 둡니다. IntelliJ, VS Code,
AI Agent, CI에서도 필요한 환경변수나 비밀값은 shell startup 파일에 넣지 말고
IDE/CI secret 설정, OS credential store 또는 Linux `environment.d`를
사용하세요. 이렇게 하면 non-interactive shell에 임의 코드와 네트워크 초기화가
섞이지 않습니다.

`bin/dotfiles-apply`는 starship 초기화 코드를
`${XDG_CACHE_HOME:-~/.cache}/zsh/starship-init.zsh`에 생성합니다. 셸 startup은
캐시를 읽기만 하며 캐시 파일을 생성하거나 수정하지 않습니다.

같은 적용 과정에서 `${ZDOTDIR:-$HOME}/.zcompdump`를 제거해 새로 설치한
completion도 반영합니다. 다음 새 셸에서 첫 Tab을 누르면 자동완성 캐시를
다시 생성합니다. 도구를 별도로 설치한 뒤에는 `bin/dotfiles-zsh-cache`를
실행하고 새 셸을 열면 됩니다.

fnm은 `.node-version` 또는 `.nvmrc`가 있는 프로젝트에서만 shell integration을
활성화합니다. 프로젝트 안에서 터미널을 바로 연 경우에는 첫 입력 직전에 한 번
확인하고, 이후에는 fnm의 디렉터리 변경 hook이 버전을 관리합니다.

JetBrains의 WSL/IJent 환경 수집은 pseudo-TTY를 사용하므로 일반 TTY 검사만으로는
터미널 세션과 구분할 수 없습니다. `INTELLIJ_ENVIRONMENT_READER`가 설정된 셸은
`.zshenv`의 export만 유지하고 `.zprofile.local`, prompt, ZLE 플러그인 및 기타
interactive 초기화를 건너뜁니다. 해당 변수를 설정하지 않는 IJent 2026.2
환경 리더는 `.zshenv`에서 IJent 임시 작업 디렉터리와 `ijent` 부모 프로세스의
조합으로 식별합니다. 부모 확인에는 zsh 내장 `read`만 사용합니다.
환경 리더에서는 터미널 초기화를 건너뛰되 셸을 종료하지 않아 IJent의
환경 조회 요청에 응답할 수 있도록 유지합니다.

## 진단과 검증

설정 적용 후 `dotfiles doctor`로 필요한 명령, 관리 링크, Git include,
셸 source block, 캐시와 clipboard 도구를 읽기 전용으로 확인합니다.
문제가 있으면 종료 코드 1과 `WARN` 항목을 출력합니다.
적용 전에는 `bash bin/dotfiles-doctor`로 직접 실행할 수 있습니다.

```bash
python3 -m unittest discover -s tests -v
```

검증은 임시 HOME에서 적용·재적용·제거, 사용자 설정 보존과 Neovim 업데이트
실패 시 복구를 확인하며 실제 홈 설정과 시스템 설치는 변경하지 않습니다.
GitHub Actions에서도 같은 검증을 실행합니다.

Neovim의 `lazy-lock.json`을 추적합니다. 새 컴퓨터에서는 `:Lazy restore`로
기록된 버전을 적용하고, 플러그인 업데이트 시 lockfile 변경도 함께 검토합니다.
자동 업데이트 검사는 끄고 `:Lazy check` / `:Lazy update`로 직접 실행합니다.
탐색기는 숨김 파일과 Git에서 무시한 파일을 기본적으로 숨기며 `H`로 표시를
토글합니다. Clipboard는 LazyVim 기본값을 따라 로컬에서 자동 연동하고 SSH에서는
자동 연동하지 않습니다. YAML/JSON 스키마는 해당 언어 서버가 시작할 때 로드합니다.

설치 시 Claude 설정은 기존 값을 우선하며 hook 배열에는 중복 없이 공통 항목을
추가합니다. `--purge`는 공통 값과 같은 항목만 제거하고 수정된 값은 보존합니다.
제거 시 현재 설정이 남아 있으면 `.bak.*` 백업을 덮어 복원하지 않습니다.
Neovim 업데이트는 다운로드·압축 해제·실행 확인 후 교체하며 실패하면 기존
설치를 보존하거나 복원합니다.
