# dotfiles

## Linux / macOS / WSL

사전 준비: `git`, `curl`

```bash
git clone git@github.com:dornol/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

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

`.gitconfig`, `.claude/settings.json`, `.claude/hooks/notify.sh` 적용됨 (MCP 설정은 유지)

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

셸 시작은 네트워크 접근이나 파일 쓰기를 하지 않습니다. 업데이트는 명시적으로
실행합니다:

```bash
dotfiles-update
```

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

fnm은 `.node-version` 또는 `.nvmrc`가 있는 프로젝트에서만 shell integration을
활성화합니다. 프로젝트 안에서 터미널을 바로 연 경우에는 첫 입력 직전에 한 번
확인하고, 이후에는 fnm의 디렉터리 변경 hook이 버전을 관리합니다.

JetBrains의 WSL/IJent 환경 수집은 pseudo-TTY를 사용하므로 일반 TTY 검사만으로는
터미널 세션과 구분할 수 없습니다. `INTELLIJ_ENVIRONMENT_READER`가 설정된 셸은
`.zshenv`의 export만 유지하고 `.zprofile.local`, prompt, ZLE 플러그인 및 기타
interactive 초기화를 건너뜁니다. 해당 변수를 설정하지 않는 IJent 2026.2
환경 리더는 `.zshenv`에서 IJent 임시 작업 디렉터리와 `ijent` 부모 프로세스의
조합으로 식별합니다. 부모 확인에는 zsh 내장 `read`만 사용합니다. 이 버전의
IJent가 환경 조회 명령을 보내지 않고 기본 zsh prompt에서 대기하는 경우에는
필수 export 구성이 끝난 직후 해당 probe shell만 종료하여 IDE가 30초 동안
멈추는 것을 방지합니다.
