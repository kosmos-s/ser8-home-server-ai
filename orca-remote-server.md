# Orca 원격 서버 구성

> 2026-10-22 SER8 Claude Code 세션(SSH 접속 후 tmux 안에서 실행)에서 직접 설치·확인한 기록입니다. UFW 규칙 순서와 노트북 화면 상태는 사용자가 제공한 출력·화면 설명에 근거합니다. 명령 예시의 `<placeholder>`는 실제 운영 값이 아닙니다. 페어링 링크·토큰·프로필 백업은 이 문서와 Git에 남기지 않습니다.

## 현재 상태

| 항목 | 상태 | 근거 |
|---|---|---|
| 앱·번들 CLI 설치 | **완료** — 1.4.237, 사용자 전용 | 직접 확인 |
| 체크섬 검증 | **완료** — 릴리스 `latest-linux.yml`의 sha512·크기와 일치 | 직접 확인 |
| 헤드리스 실행 요구 사항 | Xvfb·`--no-sandbox`·AppArmor 완화 **불필요** | 직접 확인 |
| 접근 제한 (UFW) | IPv4·IPv6 모두 "tailscale0 허용 → 같은 포트 일반 차단" 순서 | 사용자 제공 출력 |
| 상시 실행 | **완료** — 공식 systemd 사용자 서비스 `active`·`enabled`, linger 켜짐 | 직접 확인 (재부팅 시험은 하지 않음) |
| 독립 프로젝트 | **완료** — `github:kosmos-s/ser8-home-server-ai`, Git 저장소, `main` | 직접 확인 |
| 노트북 연결 | **재접속 확인** — 서비스 전환 후 서버에 페어링 클라이언트 접속 기록 | 서버 기록 직접 확인 |
| 노트북 사이드바 Unknown 항목 | **미해결** — 노트북 쪽 표시 상태로 판단, 노트북에서 정리 필요 | 서버 조회·코드 확인, 노트북은 미접근 |
| Orca에서 에이전트 실행 | Claude는 실행되었으나 권한 생략 모드 확인 화면에서 종료, Codex는 시험 보류 | 직접 확인 |
| 데스크톱 연결 | **미완료** — 확인 당시 Tailscale 오프라인 | 직접 확인 |

## 설치 정보

| 항목 | 값 |
|---|---|
| 출처 | GitHub `stablyai/orca` 공식 릴리스 (안정판) |
| 버전 | 1.4.237 (2026-10-21 배포) |
| 배포본 | `orca-linux.AppImage` (x86_64) |
| 설치 방식 | AppImage를 `--appimage-extract`로 사용자 디렉터리에 풀어 설치 |
| 설치 위치 | `~/.local/opt/orca/1.4.237`, `~/.local/opt/orca/current` → `1.4.237` |
| CLI | `~/.local/bin/orca-ide` → `~/.local/opt/orca/current/resources/bin/orca-ide` |
| 프로필 | `~/.config/orca` (`ORCA_USER_DATA_PATH`) |
| 실행 계정 | 일반 사용자 계정 (root·Docker 그룹 권한 추가 없음) |

### 왜 압축 해제 방식인가

- 서버에 `libfuse2`가 없어 AppImage를 그대로 실행할 수 없습니다. 압축을 풀면 FUSE 없이 실행됩니다.
- `.deb`는 시스템 전역 설치라 root가 필요합니다. 사용자 전용 설치를 우선했습니다.
- 버전별 디렉터리와 `current` 링크를 두면 새 버전을 풀고 링크만 바꿔 업데이트할 수 있습니다. 이 방식에서는 AppImage 자동 업데이트가 동작하지 않으므로 업데이트는 수동입니다.

### GNOME 화면 낭독기와의 구분

`/usr/bin/orca`는 Ubuntu `orca` 패키지(GNOME 화면 낭독기)입니다. 개발 도구 Orca의 Linux CLI 이름은 공식 문서대로 `orca-ide`이므로 충돌하지 않습니다. 공식 문서의 `orca ...` 명령은 이 서버에서 `orca-ide ...`로 실행합니다.

### 헤드리스 실행에 Xvfb가 필요 없는 이유

번들 CLI 스크립트는 `ELECTRON_RUN_AS_NODE=1`로 Electron을 Node 모드로 실행합니다. 이 모드에서는 Chromium 창과 GPU·sandbox 초기화가 일어나지 않습니다. `orca serve`의 기본 런타임도 Node 서버(orcad)입니다.

## 네트워크와 접근 제한

- `orca serve`에는 수신 주소 옵션이 없고, 실제로 모든 IPv4 인터페이스(`0.0.0.0`)에 바인딩됩니다. 서버 로그도 "포트에 닿을 수 있는 누구나 페어링을 시도할 수 있다"고 경고합니다.
- `--pairing-address`는 클라이언트에게 알려 줄 주소일 뿐 접근 제한이 아닙니다.
- 그래서 UFW로 Orca 포트를 Tailscale 인터페이스에서만 허용하고 나머지 경로는 거부했습니다. UFW는 위에서부터 처음 맞는 규칙을 적용하므로, 기존의 광범위한 허용 규칙보다 앞에 넣었습니다(`prepend`).
- 공인 인터넷 포트 개방, 방화벽 초기화, SSH 정책 변경은 하지 않았습니다.

```bash
# 예시 — 실제 포트는 <orca-port>
sudo ufw prepend deny proto tcp to any port <orca-port> comment 'orca serve: block non-tailscale'
sudo ufw prepend allow in on tailscale0 proto tcp to any port <orca-port> comment 'orca serve: tailscale only'
```

## 서버가 꺼진 문제와 서비스 전환

- **현상**: 노트북 Orca에서 SER8 서버가 오프라인으로 표시됐습니다.
- **원인**: 처음 페어링할 때 `orca-ide serve`를 노트북의 SSH 세션 안에서 포그라운드로 실행했습니다. SSH 세션이 끝나자 서버 프로세스도 함께 종료됐습니다. 사용자 서비스는 아직 설치하기 전이었고, Tailscale 연결은 정상이었습니다. 따라서 서비스 실패나 네트워크 문제가 아니었습니다.
- **조치**: 설치 버전의 공식 명령으로 사용자 서비스를 구성했습니다.

  ```bash
  ~/.local/bin/orca-ide serve service install --port <orca-port> --pairing-address <server-tailscale-address>
  ```

  이 명령은 `~/.config/systemd/user/orca-serve.service`를 만들고 `orca serve --supervise --no-pairing`을 실행합니다. 서비스는 페어링 링크를 출력하지 않으며, 실패하면 간격을 늘려 가며 재시작합니다.
- **확인**: `active`·`enabled`, 재시작 0회, linger 켜짐을 확인했습니다. 실행 계정은 일반 사용자이고 프로필은 기존과 같으며, PATH에 `~/.local/bin`이 있어 `claude`·`codex` 경로가 잡힙니다. 기존 페어링 정보는 같은 프로필에 유지됐고, 전환 후 노트북 클라이언트의 접속 기록이 갱신됐습니다.
- **한계**: 부팅 후 자동 시작은 linger와 `enabled` 설정으로 확인했을 뿐, 실제 재부팅 시험은 하지 않았습니다.
- **배운 점**: SSH 세션 안의 포그라운드 프로세스는 세션이 끝나면 함께 종료됩니다. 상시 실행할 서버는 서비스 관리자에 맡기고, 대화형 작업만 tmux로 분리합니다.

## 잘못된 프로젝트 연결과 독립 프로젝트 재등록

- **현상**: 노트북 사이드바에서 SER8 작업 공간이 노트북(Windows)의 다른 GitHub 저장소 프로젝트 아래에 묶여 보였습니다.
- **원인**:
  - Orca는 프로젝트 ID를 저장소 기록의 `upstream` 값으로 먼저 정하고, 이 값이 없을 때만 Git 원격으로 정합니다(설치본 코드 확인).
  - SER8 폴더가 Git이 아닌 **폴더(`folder`)** 종류로 그 프로젝트에 추가되면서, 다른 저장소의 이름이 `upstream`으로 기록됐습니다.
  - Orca는 Git 원격이 다른 저장소를 가리키면 이런 연결을 거부하지만, 폴더 종류로 가져올 때는 원격을 확인하지 않아 그 검사를 통과했습니다.
- **분리 방법 조사**:
  - 사이드바 그룹은 여러 프로젝트를 한 머리글 아래 모아 보여 줄 뿐, 한 프로젝트 안의 작업 공간을 떼어 내지 못합니다.
  - CLI에는 `upstream`이나 프로젝트 ID를 바꾸는 명령이 없습니다.
  - 같은 경로로 `repo add`를 다시 하면 기존 기록을 그대로 돌려줍니다.
- **조치**:
  1. Orca 프로필을 비공개 위치에 백업했습니다.
  2. 대상 setup 하나만 해제했습니다. `--force` 없이는 "저장된 작업 공간 정보 1건" 때문에 거부되어, 사용자 승인 후 해당 setup에만 `--force`를 적용했습니다.
  3. 같은 폴더를 경로만 지정해 Git 저장소로 다시 등록했습니다.

  ```bash
  ~/.local/bin/orca-ide project setup-delete --setup <wrong-setup-id> --host local --force
  ~/.local/bin/orca-ide repo add --path <server-repo-path>
  ```
- **삭제 범위**: `--force`가 지운 것은 Orca의 작업 공간 메타데이터와 탭·터미널 복원 기록뿐입니다. 폴더, `.git`, 브랜치, 커밋하지 않은 변경, stash, Claude 대화 기록은 그대로였고, 작업 전후 Git 상태가 같음을 비교했습니다.
- **결과**: 프로젝트 ID `github:kosmos-s/ser8-home-server-ai`, 종류 Git, 브랜치 `main`. 노트북 사이드바에서도 독립 프로젝트 아래 `main`이 표시됐다고 사용자가 확인했습니다.

## 노트북 사이드바의 Unknown 항목

- **현상**: 재등록 후 노트북 사이드바에 "Unknown" 머리글 아래 예전 SER8 항목이 남았습니다(사용자 보고).
- **서버 확인**: CLI 조회(프로젝트·setup·저장소·작업 공간·터미널)와 현재 DB 사본의 읽기 전용 조회에서 이전 setup ID와 이전 프로젝트 이름은 나오지 않았습니다. 새 ID는 같은 방법으로 검색됨을 확인했습니다. 이전 ID는 DB의 WAL·자동 백업 파일과 trace 로그, 이전 터미널 기록 파일 같은 과거 기록에만 남아 있습니다.
- **원인 판단**: 설치본 코드에서 사이드바는 항목의 저장소 ID가 클라이언트의 현재 저장소 목록에 없을 때 "Unknown" 머리글을 붙입니다. 서버에는 이전 등록이 없으므로, 노트북 Orca가 지워진 저장소 ID를 가리키는 작업 공간 행이나 알림 행을 아직 들고 있는 것으로 판단했습니다.
- **해결 범위**: 페어링은 노트북 → 서버 방향이라, 서버 CLI로 노트북의 등록·화면 상태를 읽거나 고치는 공식 기능은 없습니다. SER8에는 노트북으로 가는 SSH 설정도 없습니다. 그래서 서버에서는 정리하지 않았고, 노트북에서 정리할 절차만 아래에 정리했습니다. 노트북 상태를 직접 보지 못했으므로 이 판단은 노트북 확인 전까지 추정입니다.

### 노트북에서 정리하는 순서

1. **설정 → Remote Orca Servers**에서 SER8이 연결됨인지 확인합니다. 끊겨 있으면 **Connect**를 누릅니다.
2. Orca를 완전히 종료했다가 다시 실행해, 서버의 최신 목록을 다시 받습니다.
3. 그래도 Unknown이 남아 있으면 그 아래 항목이 무엇인지 확인합니다.
   - 알림·완료 표시 같은 행이면 닫기·읽음 처리를 합니다.
   - 작업 공간 행이면 마우스 오른쪽 메뉴에서 **Orca에서만 제거**하는 항목을 고릅니다. 실제 파일이나 worktree를 지우는 항목은 고르지 않습니다.
4. 남는 경우 노트북 PowerShell에서 읽기 전용 조회 결과를 확인한 뒤 다음 조치를 정합니다.

   ```powershell
   orca project list --json
   orca project setups --json
   orca host list
   ```

메뉴 이름은 설치본에서 정확히 확인하지 못했습니다. 노트북의 다른 프로젝트와 그 작업 공간은 정리 대상이 아닙니다.

## 에이전트 실행 확인

| 항목 | 결과 |
|---|---|
| Claude Code·Codex CLI | 설치·버전 확인, 각 로그인 상태 명령 정상 종료 |
| Orca 관리 계정 | 등록 없음 — 시스템 기본(기존 CLI 로그인)을 사용 |
| 서비스 PATH | `claude`·`codex` 경로 확인 |
| Orca에서 Claude 실행 | 작업 공간에서 터미널로 실행됨. 다만 Orca 기본 인자 `--dangerously-skip-permissions` 때문에 Claude가 권한 생략 모드 동의 화면에서 멈췄습니다. 대신 승인하지 않고 터미널을 닫았습니다 |
| Orca에서 Codex 실행 | **보류** — 기본 인자가 `--dangerously-bypass-approvals-and-sandbox`(승인·샌드박스 없이 실행)라서 시험하지 않았습니다 |

서버 프로필의 에이전트 기본 인자는 Orca의 권한 생략(yolo) 모드로 설정돼 있습니다. 이 프로필에서 확인 질문 없이 에이전트를 실행하는 것은 운영 서버 전체에 대한 권한을 주는 것과 같습니다. 에이전트 권한 모드를 manual(매번 승인) 또는 auto로 바꾼 뒤 한 작업 공간에서 Claude → Codex 순서로 최소 확인을 하는 것이 다음 단계입니다. CLI에는 이 설정을 바꾸는 명령이 없어서, 서버에 연결된 노트북 Orca 설정에서 바꿔야 합니다.

## tmux 사용 범위

- tmux 3.4가 설치되어 있고, 이번 Claude Code 작업은 SSH로 접속한 뒤 tmux 세션 안에서 진행했습니다(직접 확인).
- tmux는 SSH 연결이 끊겨도 대화형 터미널 작업을 유지하는 용도로 씁니다. Orca 서버는 tmux가 아니라 systemd 사용자 서비스로 실행합니다.

## 데스크톱 연결 절차 (미완료)

1. 데스크톱에서 Tailscale에 로그인해 연결 상태를 확인합니다.
2. Orca를 설치·실행하고 **설정 → Remote Orca Servers → Add Server**를 엽니다.
3. 새 페어링이 필요합니다. 서비스는 페어링 링크를 출력하지 않으므로, 서버를 두 개 띄우지 않도록 SER8 터미널에서 서비스를 잠시 멈추고 포그라운드로 링크를 만듭니다. 링크는 그 터미널에서만 보고 문서·대화에 남기지 않습니다.

   ```bash
   systemctl --user stop orca-serve
   ORCA_USER_DATA_PATH="$HOME/.config/orca" ~/.local/bin/orca-ide serve --port <orca-port> --pairing-address <server-tailscale-address>
   # 데스크톱에서 Add Server 완료 후 Ctrl-C
   systemctl --user start orca-serve
   ```

   서비스를 멈춘 동안 노트북 연결도 잠시 끊깁니다. 서비스를 다시 시작하면 기존 페어링으로 재접속합니다.
4. 이름(예: `SER8`)과 페어링 URL을 입력해 **Add Server**를 누르고, 끊김으로 보이면 **Connect**를 누릅니다.
5. 사이드바의 `ser8-home-server-ai` → `main`을 열어 노트북과 같은 작업 공간이 보이는지 확인합니다. 원격에서 작업하려면 **Advanced → Active Server**에서 SER8을 고릅니다.

## 남은 작업

- 노트북 Unknown 항목 정리와 결과 확인
- 서버 프로필의 에이전트 권한 모드 조정 후 Claude → Codex 순차 최소 확인
- 데스크톱 연결과 같은 작업 공간 이어 사용 확인
- 실제 재부팅 후 서비스 자동 시작 확인 (사용자 선택 전까지 시험하지 않음)
- Tailscale ACL에서 접근 가능한 기기 범위 점검
