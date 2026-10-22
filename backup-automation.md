# 모니터링 백업 자동화 초안

> 2026-10-21 작성. 스크립트와 systemd 예시는 **실행·시험·설치하지 않은 초안**입니다. 대상 경로와 기존 예약 작업 유무는 같은 날 Claude Code 세션에서 서버 파일을 읽기 전용으로 확인했습니다. 컨테이너 상태는 Docker 권한이 없어 직접 확인하지 않았습니다.

## 2026-10-22 읽기 전용 재확인

- 저장소의 스크립트·systemd 파일은 계속 초안입니다. 배포 위치의 스크립트와 모니터링 전용 system/user timer는 없고, 사용자 crontab도 없는 상태를 직접 확인했습니다. 이 사실은 시스템 전체의 모든 백업 작업 부재를 뜻하지 않습니다.
- 비공개 모니터링 백업 디렉터리는 접근 제한으로 내부 목록을 읽지 못했습니다. 수동 백업·초기 압축/체크섬 검사 성공은 과거 기록이며 현재 무결성·복원 가능성을 재검증하지 않았습니다.
- 백업 실행·dry-run·문법 재시험·서비스 중단·timer 설치는 하지 않았습니다. 외부 장치·마운트·예약·보관 정책은 계속 미정입니다. Open WebUI 제외 결정을 유지하고 n8n 데이터를 임의로 새 백업 대상에 넣지 않았습니다.
- 기존 암호화 백업·방화벽 백업·설정 백업·stash는 내용 공개·복사·삭제 없이 보존합니다. 현재 사용과 정리 시 영향은 [정리 후보](./usage-guide.md#삭제하지-않은-정리-후보), 추가 권한 명령은 [직접 점검](./evidence.md)을 참고합니다.

## 초안 작성 당시 상태와 후속 확인

| 항목 | 상태 |
|---|---|
| 수동 백업 | 사용자 보고 기준 완료 (기존 기록은 [환경·구축 증거](./evidence.md) 참고) |
| 기존 백업 스크립트·systemd timer·cron | 모니터링 백업용은 없음을 확인 (Ubuntu 기본 `dpkg-db-backup.timer`만 존재) |
| 백업 스크립트 [`scripts/backup-monitoring.sh`](./scripts/backup-monitoring.sh) | 초안 작성, 정적 코드 검토와 문법 검사(`bash -n`)만 수행. 실행·dry-run 하지 않음 |
| systemd 예시 [`examples/systemd/`](./examples/systemd/) | 예시 작성, 설치·활성화하지 않음 |
| 외부 저장장치 | **아직 정하지 않음** |
| 오래된 백업 정리 | 구현하지 않음 (자동 삭제 없음) |

## 백업 대상

| 서비스 | 포함 | 비고 |
|---|---|---|
| Beszel Hub | Compose 파일, `beszel_data` (SQLite `data.db`·`auxiliary.db`와 `-wal`·`-shm`, Hub 키) | DB 일관성을 위해 잠시 중지 |
| Beszel Agent | Compose 파일(같은 디렉터리), `beszel_agent_data` (식별 파일) | 실행 중 변경되지 않는다는 근거가 없어 함께 잠시 중지 |
| Uptime Kuma | Compose 파일, `data` (SQLite `kuma.db`와 `-wal`·`-shm`, 설정·업로드 파일) | DB 일관성을 위해 잠시 중지 |
| 제외 | `beszel_socket` (실행 중 생성되는 소켓), **Open WebUI 전체** | Open WebUI는 사용자 선택으로 제외 |

백업본에는 Agent 연결 인증값과 Hub 개인 키가 들어 있습니다. 그래서 파일을 `0600`, 디렉터리를 `0700`으로 만들고, 저장소나 공개 위치에는 두지 않습니다.

## 왜 컨테이너를 잠시 멈추는가

두 서비스는 SQLite를 WAL 모드로 사용합니다. WAL 모드에서는 새 변경이 먼저 `-wal` 파일에 쌓이고 나중에 본 DB 파일로 합쳐집니다. 실행 중에 파일을 복사하면 본 파일과 `-wal` 파일의 시점이 어긋날 수 있습니다. 그러면 복원했을 때 데이터가 빠지거나 DB가 손상될 수 있습니다.

실행 중에 일관된 사본을 만들려면 SQLite의 `.backup` 기능이 필요합니다. 하지만 서버 호스트에 `sqlite3` 명령이 없고, 이번 범위에서는 패키지를 설치하지 않습니다. 그래서 이 초안은 다음 순서로 동작합니다.

1. 아무것도 멈추기 전에 대상 컨테이너(Beszel Agent·Hub, Uptime Kuma)의 상태를 모두 확인합니다. 다음 경우에는 아무것도 멈추지 않고 중단합니다. 상태를 모른 채 실행 중인 DB를 복사하지 않기 위해서입니다.
   - Docker 조회가 실패한 경우
   - 컨테이너를 찾지 못한 경우
   - `restarting`·`paused`처럼 예상하지 못한 상태인 경우
2. 원래 **실행 중이던** 컨테이너만 `docker compose stop`으로 멈추고, 멈춘 목록을 기억합니다. 순서는 Agent → Hub입니다.
3. 서비스 디렉터리를 `tar.gz`로 묶습니다. 데이터가 몇 MB 수준이라 중지 시간은 짧을 것으로 예상하지만, 실제로 측정하지는 않았습니다.
4. 검사보다 먼저 **기억해 둔 컨테이너만** 멈춘 순서의 역순(Hub → Agent)으로 `docker compose start`합니다. 그다음 상태가 실제로 `running`인지 확인합니다. 원래 멈춰 있던 컨테이너는 시작하지 않습니다.

Agent를 처음에는 멈추지 않으려 했습니다. 하지만 2026-10-21 읽기 전용으로 확인해 보니 `beszel_agent_data` 디렉터리의 수정 시각(21:23)이 그 안의 식별 파일 생성 시각(20:41)보다 늦었습니다. 실행 중에 이 디렉터리에서 파일이 생기거나 지워졌을 수 있다는 뜻입니다. 공식 문서로 확인한 근거도 없어서 Agent도 함께 멈춥니다.

중지되는 동안 Uptime Kuma 감시와 Beszel 수집에는 짧은 공백이 생깁니다. 게임 서버, Ollama, Open WebUI는 건드리지 않습니다.

## 실행 방법 (초안 — 아직 실행하지 않음)

```bash
# 1) 실행 계획만 확인 (컨테이너·파일 변경 없음)
sudo ./scripts/backup-monitoring.sh --dest <backup-destination> --dry-run

# 2) 실제 백업
sudo ./scripts/backup-monitoring.sh --dest <backup-destination>

# 외부 저장장치를 정한 뒤: 루트 디스크면 중단
sudo ./scripts/backup-monitoring.sh --dest <backup-destination> --require-mount
```

결과는 `<backup-destination>/monitoring-<날짜-시각>/`에 생깁니다.

- `monitoring-<날짜-시각>.tar.gz`: 백업 압축본
- `monitoring-<날짜-시각>.files.txt`: 압축본에 들어 있는 파일 목록
- `SHA256SUMS`: 위 두 파일의 체크섬

## 안전장치와 오류 처리

| 상황 | 동작 |
|---|---|
| root 아님, 필요한 명령·Compose 파일 없음, 저장 위치 없음·쓰기 불가 | 시작 전에 중단 |
| 저장 위치가 백업 원본 내부 | 중단 |
| 같은 이름의 백업 디렉터리가 이미 있음 | 중단 (기존 백업을 덮어쓰거나 그 안에 넣지 않음) |
| 여유 공간이 원본 크기의 110% 미만, 마운트·크기 정보 조회 실패 | 중단 |
| 저장 위치가 루트 파일시스템이거나 원본과 같은 파일시스템 | 경고. `--require-mount`를 주면 중단 |
| 이미 다른 백업이 실행 중 | `flock`으로 즉시 중단 (`/run/lock/backup-monitoring.lock`) |
| 컨테이너 상태 조회 실패, 컨테이너 없음, 예상 밖 상태 | 아무것도 멈추기 전에 중단 |
| 압축·검사 중 오류, Ctrl+C(INT)·TERM·HUP 신호 | 이 스크립트가 멈춘 컨테이너만 재시작하고, 이번 실행이 만든 작업 디렉터리(`.incomplete-…`)만 삭제. 복구하는 동안에는 신호를 무시해 재시작이 끊기지 않게 함 |
| 컨테이너 재시작 실패, 재시작 후 `running`이 아님 | 서비스 이름과 수동 재시작 명령을 출력. 백업이 만들어졌으면 보존하되 종료 코드 1로 실패를 알림 |

작업은 저장 위치 안의 임시 디렉터리에서 진행합니다. 이 디렉터리는 `mktemp`로 매번 새 이름을 받아 만듭니다. 압축 읽기 검사(`gzip -t`, `tar -t`)와 체크섬 확인을 모두 통과해야 최종 이름으로 옮깁니다. 실패했을 때 지우는 것은 이번 실행의 임시 디렉터리뿐입니다. 이미 있는 `monitoring-…` 백업은 지우거나 덮어쓰지 않습니다. 따라서 `monitoring-…`이라는 이름이 붙은 디렉터리는 이 검사를 통과한 백업입니다. 다만 압축 검사와 체크섬은 파일이 손상되지 않았다는 것만 보여 줄 뿐, 복원이 된다는 증거는 아닙니다.

`원본과 같은 파일시스템` 검사는 파일시스템 장치 번호만 비교합니다. 같은 물리 디스크의 다른 파티션은 구분하지 못하므로, 외부 저장장치인지는 직접 확인해야 합니다.

## 다른 저장장치에 복사해야 하는 이유

같은 디스크에 있는 백업은 실수로 지운 파일이나 서비스 설정 오류에는 도움이 됩니다. 하지만 SSD 고장, 파일시스템 손상, 서버 분실·도난, 랜섬웨어처럼 **원본과 백업을 함께 잃는 상황**에는 대비할 수 없습니다. 그래서 백업은 원본과 다른 물리 장치에 따로 있어야 의미가 있습니다.

외부 저장장치(USB 디스크, NAS 등)는 **아직 정하지 않았습니다.** 장치를 정하기 전까지는 `--dest`에 같은 서버의 디렉터리를 줄 수 있습니다. 이 경우 스크립트는 경고를 출력합니다. systemd 예시에는 `RequiresMountsFor=`와 `--require-mount`가 들어 있습니다. 장치가 마운트되지 않았을 때 빈 마운트 지점, 즉 루트 디스크에 백업이 쓰이는 것을 막기 위해서입니다.

## 예약 실행 예시 (설치하지 않음)

- [`backup-monitoring.service`](./examples/systemd/backup-monitoring.service)
  - 한 번 실행하고 끝나는 `oneshot` 서비스입니다.
  - 낮은 CPU·IO 우선순위로 실행하고, 저장장치가 마운트된 경우에만 실행합니다.
  - `KillMode=mixed`를 씁니다. 서비스를 멈출 때 SIGTERM이 스크립트에만 가므로, 컨테이너를 재시작하는 정리 단계가 함께 종료되지 않습니다.
- [`backup-monitoring.timer`](./examples/systemd/backup-monitoring.timer)
  - 하루 한 번 실행합니다. 정확한 시각은 `<HH:MM>`으로 비워 두었습니다.
  - 서버가 꺼져 있어 놓친 실행은 부팅 후 한 번 실행합니다(`Persistent=true`).

나중에 설치할 때 쓸 sudo 명령입니다(**이번 작업에서 실행하지 않음**). 실행 전에 두 예시 파일의 `<backup-destination>`과 `<HH:MM>`을 실제 값으로 바꿔야 합니다.

```bash
sudo install -m 0750 -o root -g root scripts/backup-monitoring.sh /usr/local/sbin/backup-monitoring.sh
sudo install -m 0644 -o root -g root examples/systemd/backup-monitoring.service /etc/systemd/system/backup-monitoring.service
sudo install -m 0644 -o root -g root examples/systemd/backup-monitoring.timer /etc/systemd/system/backup-monitoring.timer
sudo systemd-analyze verify /etc/systemd/system/backup-monitoring.service /etc/systemd/system/backup-monitoring.timer
sudo systemctl daemon-reload
sudo /usr/local/sbin/backup-monitoring.sh --dest <backup-destination> --require-mount --dry-run
sudo systemctl start backup-monitoring.service
sudo systemctl status backup-monitoring.service --no-pager
sudo journalctl -u backup-monitoring.service --no-pager -n 50
sudo systemctl enable --now backup-monitoring.timer
systemctl list-timers backup-monitoring.timer --no-pager
```

예약을 일시 중지하거나 해제하는 명령은 다음과 같습니다.

```bash
sudo systemctl stop backup-monitoring.timer       # 일시 중지 (재부팅 후에는 다시 동작)
sudo systemctl disable --now backup-monitoring.timer  # 예약 해제
```

## 남은 결정·검증

- 외부 저장장치 종류와 마운트 경로
- 예약 실행 시각과 주기
- 오래된 백업을 보관하는 기간과 정리 방법 (지금은 자동 삭제 없음)
- 스크립트 첫 실행(`--dry-run` → 실제 백업)과 중지 시간 측정
- 백업 복원 시험 (지금까지 사용자 선택으로 생략)

## 관련 문서

- [프로젝트 소개](./README.md)
- [환경·구축 증거](./evidence.md)
- [단계별 계획](./roadmap.md)
