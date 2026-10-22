# n8n 최소 구성과 첫 수동 워크플로

> 2026-10-22 SER8 Claude Code 세션에서 작성했습니다. 이 세션 계정은 Docker 그룹이 아니고 sudo 비밀번호가 필요해서, 컨테이너 생성·시작과 UFW 규칙 추가는 사용자가 직접 실행했습니다. 아래 상태표는 근거(직접 확인 / 사용자 보고 / 사용자 화면)를 함께 적습니다. 예시의 `<placeholder>`는 실제 운영 값이 아니며, 실제 운영 Compose·DB·암호화 키·실행 데이터는 저장소에 넣지 않습니다.

## 2026-10-22 읽기 전용 재확인

- 운영 Compose의 지정 이미지는 n8n 2.44.5 태그·digest이며, 호스트 loopback 바인딩과 해당 TCP 소켓 수신을 직접 확인했습니다. Docker 소켓 권한이 없어 실제 실행 이미지·컨테이너 healthy를 재확인한 것은 아닙니다.
- 기존 워크플로·실행 이력 DB·암호화 키·계정 데이터는 열거나 복사하지 않았습니다. 첫 수동 HTTP 확인 성공은 기존 사용자 화면 근거로 유지하며 이번에 재실행하지 않았습니다.
- 정기 실행은 사용자 선택으로 계속 보류합니다. 알림·AI 연동·서비스 제어·추가 워크플로는 구성하지 않습니다. Open WebUI·Ollama·운영 컨테이너 설정도 변경하지 않았습니다.
- 아래 설치·가져오기 절차는 최초 구축 기록입니다. 현재 인스턴스와 저장된 수동 워크플로를 재설치·재가져오기하는 다음 작업으로 해석하지 않습니다. 평소 접속·사용과 보류 항목은 [사용 가이드](./usage-guide.md)를 우선합니다.

## 최초 도입 당시 상태와 근거

| 항목 | 상태 | 근거 |
|---|---|---|
| 기존 n8n 설치·디렉터리·포트 사용 | 없음 확인 (컨테이너 목록은 Docker 권한 부족으로 직접 조회하지 못함) | 직접 확인 |
| 버전 선택 | n8n 2.44.5 — GitHub 최신 안정 릴리스, Docker `stable`·`latest` 태그와 같은 digest | 직접 확인 |
| Compose 구성 | 작성·문법 검사(`docker compose config -q`) 통과, 운영 위치에 배치된 파일이 검사한 파일과 동일 | 직접 확인 |
| 컨테이너 시작·로컬 웹 응답 | 컨테이너 실행, 호스트 loopback의 `/healthz` 200 | 사용자 실행, 웹 응답은 직접 확인 |
| 노트북 웹 접속·관리자 계정 생성 | 완료 | 사용자 보고 |
| 첫 수동 워크플로 | **성공** — Open WebUI `statusCode=200`, `ok=true`, `responseMs=10`, `error` 없음 (2026-10-22 11:50 KST) | 사용자 제공 화면 |
| 예약 실행·외부 알림·AI 연동·서비스 제어 | **미구성** | — |

## 구성 원칙

- **단일 컨테이너**: 기본 SQLite 저장소를 쓰는 개인용 인스턴스입니다. 영속 데이터는 named volume(`/home/node/.n8n`)에 둡니다.
- **버전 고정**: 태그와 이미지 digest를 함께 적어, 같은 파일이면 항상 같은 이미지를 받습니다.
- **접근 범위**: 웹 포트는 호스트의 `127.0.0.1`에만 게시합니다. 노트북에서는 기존처럼 Tailscale 경유 SSH 터널로 접속하므로 방화벽 변경이 필요 없습니다.
- **시간대**: `GENERIC_TIMEZONE`(n8n 예약 노드 기준)과 `TZ`(컨테이너 시스템 시간)를 모두 `Asia/Seoul`로 둡니다.
- **암호화 키**: 첫 실행 때 n8n이 무작위로 만들어 영속 볼륨에 저장합니다. 그래서 Compose 파일에 넣지 않고, 볼륨을 지우면 저장된 인증정보를 복호화할 수 없다는 점만 기억합니다.
- **도입하지 않은 것**:
  - Assistant·AI 기능, 별도 task runner 컨테이너
  - Docker-in-Docker, privileged 모드, Docker 소켓 마운트
  - 추가 AI 서비스
- **추가로 끈 것**:
  - 진단 정보 전송(`N8N_DIAGNOSTICS_ENABLED=false`). 공식 문서에 따르면 Code 노드의 Ask AI도 함께 막힙니다.
  - 개인화 질문, 공개 API
- `no-new-privileges`로 컨테이너 안에서 권한 상승을 막습니다.

예시 파일: [`examples/n8n/compose.example.yaml`](./examples/n8n/compose.example.yaml)

## 최초 설치 순서 — 구축 기록, 이번에는 실행하지 않음 (sudo 필요)

1. n8n 전용 디렉터리를 만들고 Compose 파일을 둡니다. 기존 서비스 디렉터리는 건드리지 않습니다.
2. 문법 검사 → 이미지 받기 → 시작 순서로 실행합니다.
3. 컨테이너 상태와 로컬 웹 응답(`/healthz`)만 확인합니다.

```bash
sudo install -d -o <user> -g <user> -m 755 <n8n-dir>
cp <staged-compose.yaml> <n8n-dir>/compose.yaml
cd <n8n-dir>
sudo docker compose config -q && echo "compose OK"
sudo docker compose pull
sudo docker compose up -d
sudo docker compose ps
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:<host-port>/healthz
```

## 노트북 접속과 관리자 계정

```powershell
# 노트북 PowerShell — 터널을 연 채로 둡니다
ssh -N -L <host-port>:127.0.0.1:<host-port> <user>@<server-tailscale-address>
```

브라우저에서 `http://localhost:<host-port>`를 열고, 처음 화면에서 소유자(관리자) 계정을 만듭니다. 비밀번호는 사용자만 알도록 하고 문서·저장소에 남기지 않습니다.

## 첫 워크플로: HTTP 상태 확인 (수동)

파일: [`examples/n8n/http-status-check.workflow.json`](./examples/n8n/http-status-check.workflow.json) — 공개용 예시. 대상 URL은 placeholder이며, 가져온 뒤 실제 주소로 바꿔 실행에 성공했습니다(사용자 화면)

| 노드 | 역할 |
|---|---|
| 수동 실행 (Manual Trigger) | 버튼을 눌렀을 때만 실행. 예약 없음 |
| 대상 목록 (Set, JSON) | 확인할 서비스 이름과 URL 목록 |
| 대상 분리 (Split Out) | 목록을 항목별로 나눔 |
| 하나씩 확인 (Loop Over Items, 1개씩) | 항목을 차례로 처리해 응답 시간을 항목별로 잼 |
| 시작 시각 (Set) | 요청 직전 시각 기록 |
| HTTP 요청 | 제한 시간 5초, 전체 응답 받기, 4xx·5xx도 오류로 멈추지 않음, 연결 실패 시 다음 단계로 계속 |
| 결과 정리 (Set) | `service`, `statusCode`, `ok`, `responseMs`, `error`, `checkedAt`만 남김 |
| 전체 결과 (No Operation) | 반복이 끝난 뒤 모든 항목 결과를 한곳에서 확인 |

- **실패해도 결과가 남는 이유**: HTTP 요청 노드의 오류 처리가 "계속(정상 출력)"이라, 연결 실패도 `error` 필드를 가진 결과 항목이 됩니다. 반복이 끊기지 않습니다.
- **응답 시간 측정 방식**: 코드 노드 없이 항목마다 요청 직전 시각과 정리 시점 시각의 차이로 잽니다. n8n 노드 처리 시간이 몇 ms 포함되는 근사값입니다.
- 코드 노드, 알림, 서비스 제어, AI 노드는 쓰지 않습니다.

### 감시 후보와 컨테이너 접근 경로

| 후보 | 호스트 바인딩 | n8n 컨테이너에서 | 처리 |
|---|---|---|---|
| Open WebUI | 모든 인터페이스, `/health` 200 (호스트에서 확인) | `host.docker.internal` 경유. 처음엔 UFW 차단으로 타임아웃, 최소 허용 규칙 추가 후 도달 | 워크플로 대상, 실행 성공 |
| Beszel Hub | 호스트 loopback 전용 | 브리지 네트워크 컨테이너에서는 호스트 loopback에 닿을 수 없음 | **제외** — 바인딩·네트워크를 바꾸지 않기로 함 |
| Ollama | 호스트 loopback 전용 | 같은 이유로 접근 불가 | **제외** — 같은 이유 |

경로를 만들려고 기존 서비스의 바인딩·네트워크를 바꾸거나 n8n을 호스트 네트워크로 실행하지 않았습니다. 제외 항목은 나중에 별도 결정이 있을 때 다시 검토합니다.

### 최초 가져오기 절차와 수동 사용

현재는 이미 저장된 워크플로를 사용합니다. 다음 1~2단계는 처음 만들 때의 안내로 보존하며, 기존 워크플로를 중복 가져오거나 대상 설정을 덮어쓰지 않습니다.

1. n8n 화면에서 새 워크플로를 열고 JSON 내용을 붙여 넣거나 **Import from File**로 가져옵니다.
2. **대상 목록** 노드에서 URL의 placeholder를 컨테이너에서 접근 가능한 실제 주소로 바꿉니다. 실제 주소는 n8n 안에만 두고 저장소에는 남기지 않습니다.
3. **Execute workflow**를 눌러 실행하고, **전체 결과** 노드에서 항목별 결과를 확인합니다.
4. `error`에 타임아웃이 나오면 아래 "Open WebUI 요청 타임아웃"을 참고합니다. 제한 시간을 늘려 덮지 않습니다.

## Open WebUI 요청 타임아웃 (해결)

- **현상**: 첫 실행에서 Open WebUI 항목이 `statusCode=null`, `ok=false`, `responseMs≈5035`, `error="timeout of 5000ms exceeded"`로 끝났습니다(사용자 보고).
- **조사**:
  - 호스트에서는 같은 서비스의 `/health`가 200을 돌려줬습니다.
  - `host.docker.internal`은 Docker 기본 브리지의 게이트웨이 주소로 해석됐습니다(사용자 실행 조회).
  - Open WebUI는 호스트 네트워크로 직접 수신하므로, n8n 브리지에서 이 주소로 가는 요청은 FORWARD가 아니라 호스트 **INPUT** 체인을 지납니다.
  - UFW의 해당 포트 허용 규칙은 Tailscale 인터페이스와 LAN 대역에만 있었습니다. n8n 브리지에서 온 요청은 기본 정책 DROP으로 떨어집니다.
  - UFW 로그에서 `IN=<n8n-bridge> SRC=<n8n-container> DST=<host-gateway> DPT=<open-webui-port> SYN` 차단 기록 1건을 확인했습니다.
- **원인**: n8n 브리지에서 호스트로 가는 연결 요청을 UFW가 거부 응답 없이 버려서 타임아웃이 났습니다.
- **로그가 드물었던 이유**: UFW 차단 로그는 분당 3건으로 제한되는데, LAN 멀티캐스트 차단이 약 20초 간격으로 그 한도를 거의 다 썼습니다. 그래서 n8n의 재전송은 대부분 기록되지 않았습니다.
- **해결**:
  - 기존 n8n 네트워크는 그대로 두었습니다.
  - 출발지(n8n 네트워크 대역), 들어오는 인터페이스(n8n 브리지), 목적지(host-gateway 주소), TCP 포트를 모두 지정한 허용 규칙 1개만 추가했습니다(사용자 실행).
  - 방화벽 끄기, Docker 대역 전체 허용, 제한 시간 늘리기, 기존 서비스·바인딩 변경은 하지 않았습니다.

  ```bash
  sudo ufw allow in on <n8n-bridge> proto tcp from <n8n-subnet> to <host-gateway-ip> port <open-webui-port> comment 'n8n -> open-webui health only'
  ```
- **허용 범위 주의**:
  - 이 규칙은 `/health` 경로만이 아니라 n8n 네트워크에서 해당 **TCP 포트 전체**로 가는 접근을 허용합니다. 방화벽은 HTTP 경로를 구분하지 못합니다.
  - n8n 워크플로가 그 포트의 다른 경로도 호출할 수 있으므로, 워크플로 대상은 `/health`로 유지합니다.
- **재확인 조건**:
  - Docker 브리지 이름은 네트워크 ID에서 만들어집니다. `docker compose down` 등으로 n8n 네트워크가 다시 만들어지면 이름과 대역이 바뀔 수 있습니다.
  - 그러면 규칙이 더 이상 맞지 않아 다시 타임아웃이 납니다. 더 넓게 열리지는 않습니다. 새 이름으로 규칙을 바꾸고 예전 규칙은 지웁니다.
  - 자주 재생성한다면 Compose에서 브리지 이름과 대역을 고정하는 방식으로 옮깁니다.

## 남은 결정·미검증

- 예약 실행 — 사용자 선택으로 나중에 진행. 외부 알림 미사용·AI 연동 미구성 유지
- Beszel·Ollama 감시 — 컨테이너에서 접근 경로가 없어 제외 상태
- n8n 데이터 볼륨의 백업 포함 여부 (자동 백업은 외부 저장장치 결정 이후)
- 예약 실행과 알림 사용 여부 (현재는 수동 실행만)
- n8n 업데이트 방식 (태그와 digest를 함께 바꾸는 수동 업데이트 예정)
