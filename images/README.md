# 공개 이미지와 개인정보 가림 범위

> 2026-10-25 보완. 사용자가 제공한 원본 캡처에서 필요한 부분을 잘라내고 개인정보 영역만 불투명한 사각형으로 가렸습니다. 기존 AI 편집본 8장은 현재 파일·문서에서 교체했으며 과거 Git 이력은 유지합니다. 원본 전체·실제 운영 설정·인증정보는 업로드하지 않습니다.

## 처리와 검증 방법

화면 재생성 없이 ImageMagick으로 자르기·단색 가림만 적용했습니다. 교체한 8장 모두 가림 영역 밖의 RGB 픽셀이 원본의 해당 영역과 일치하는지 비교했고, 가림 영역은 불투명한 단색인지 검사했습니다. 출력 PNG의 부가 메타데이터를 제거하고 육안·OCR로 공개 내용을 다시 확인했습니다. 글자·수치·접속 상태를 새로 만들거나 바꾸지 않았습니다.

사진은 캡처 시점의 화면을 보여 줍니다. 현재 서비스 상태, 휴대폰 실사용, 재부팅 복구, 장기 가용성은 화면만으로 판단하지 않고 [날짜별 근거](../evidence.md)의 로그·사용자 보고와 구분합니다.

## 원본 기반 마스킹본 8장

| 파일 | 사용자 원본 파일 | 자르기·가림 범위 | 남겨 둔 내용 |
|---|---|---|---|
| [03-beszel-dashboard-redacted.png](./03-beszel-dashboard-redacted.png) | 스크린샷 2026-10-21 204219.png | 브라우저 영역 제거, 시스템 이름 가림 | 온라인 표시·CPU·메모리·디스크·온도 등 당시 지표 |
| [04-beszel-add-system-redacted.png](./04-beszel-add-system-redacted.png) | 스크린샷 2026-10-21 203401.png | 등록 창만 자름, 이름·호스트/IP·포트·공개 키·토큰 입력 영역 전체 가림 | 등록 메뉴·필드 이름. 등록 성공 화면은 아님 |
| [05-orca-connected-redacted.png](./05-orca-connected-redacted.png) | 스크린샷 2026-10-22 080654.png | 연결 영역만 자름, 호스트·계정 가림, 사이드바·하단 설정 제외 | 연결됨·호환됨·버전·상태 표시 |
| [09-hermes-web-redacted.png](./09-hermes-web-redacted.png) | 스크린샷 2026-10-24 010852.png | 홈 경로·세션 ID·오른쪽 대화 목록 가림 | 웹 구성·메뉴·모델·도구 목록 |
| [10-hermes-mobile-redacted.png](./10-hermes-mobile-redacted.png) | 스크린샷 2026-10-24 010935.png | 홈 경로·세션 ID 가림 | 좁은 화면의 UI. 실제 휴대폰 사용은 별도 사용자 보고 |
| [11-hermes-login-redacted.png](./11-hermes-login-redacted.png) | 스크린샷 2026-10-24 182134.png | 계정·비밀번호 입력 내부 전체 가림 | 로그인 시도 제한 문구. 하단 PUBLIC BIND 표기만으로 인터넷 공개를 판단하지 않으며, 이 환경의 수신 출력은 Tailscale 주소 바인딩 |
| [12-hermes-timeout-redacted.png](./12-hermes-timeout-redacted.png) | 스크린샷 2026-10-24 181420.png | 실제 주소 가림 | 시간 초과 문구·오류 코드 |
| [13-uptime-kuma-redacted.png](./13-uptime-kuma-redacted.png) | 스크린샷 2026-10-21 211320.png | 서비스 URL 전체·계정 아바타 가림 | HTTP 감시 항목·온라인 표시·당시 수치 |

기존 `03`·`04`·`05`·`09`~`13`의 `-ai-edited.png` 파일은 위 `-redacted.png` 파일로 대체했습니다. 원본 파일과 마스킹본은 별개이며 원본을 덮어쓰지 않았습니다.

## 추가 가림 없이 유지한 캡처 8장

아래 파일은 기존 캡처를 유지했습니다. 14·15번은 선택 메뉴 부분, 16번은 버전 안내 부분만 담긴 화면입니다. 여기서 가림 없음은 전체 데스크톱·브라우저를 자르지 않은 원본이라는 의미가 아닙니다.

| 파일 | 보여 주는 범위와 해석 |
|---|---|
| [01-tailscale-sign-in.png](./01-tailscale-sign-in.png) | 계정 없는 초기 안내. 서버 접속 성공 증거 아님 |
| [02-tailscale-connected.png](./02-tailscale-connected.png) | 클라이언트 연결 후 안내. 특정 서버 도달·정책 검증과 구분 |
| [06-n8n-timeout.png](./06-n8n-timeout.png) | 수동 HTTP 요청 실패 결과 |
| [07-n8n-http-success.png](./07-n8n-http-success.png) | 단일 HTTP 200·ok=true 성공. 성능·정기 실행 검증 아님 |
| [08-orca-removal-menu.png](./08-orca-removal-menu.png) | 제거 메뉴. 실행·해결은 별도 사용자 보고 |
| [14-hermes-model-selection.png](./14-hermes-model-selection.png) | 모델 선택 메뉴 부분 캡처, 추가 가림 없음. 사용자 원본: 스크린샷 2026-10-24 004546.png |
| [15-hermes-reasoning-selection.png](./15-hermes-reasoning-selection.png) | 추론 강도 메뉴 부분 캡처, 추가 가림 없음. 사용자 원본: 스크린샷 2026-10-24 004655.png |
| [16-pterodactyl-update-notice.png](./16-pterodactyl-update-notice.png) | 업데이트 전 버전 안내 부분 캡처, 추가 가림 없음. 사용자 원본: 스크린샷 2026-10-23 171855.png. 업데이트 완료 증거 아님 |

## 공개하지 않은 자료

- 토큰·공개 키·인증정보가 남은 등록 원본과 실제 설정 파일.
- Tailscale 기기 목록의 실제 계정·IP·호스트, 접근 정책 원문과 운영 포트 묶음.
- DHCP 예약·공유기의 IP·MAC·포트포워딩·UPnP 목록.
- 로컬 계정 경로·개인 프로젝트·대화 내용·진단 ID가 보이는 전체 화면.
- 동일 장면의 중복 캡처, 결과가 없는 초기 설정·진행 화면.

가림 작업은 실제 토큰의 교체·폐기를 뜻하지 않습니다. 화면의 `100%`·응답 시간·도구 수는 당시 표시이며 장기 가용성·성능·전체 도구 실행 결과로 일반화하지 않습니다.
