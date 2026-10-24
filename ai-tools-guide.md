# Claude·Codex 확장 구성과 사용 가이드

**2026-10-24 후속:** Orca 공용 `orca-cli`·`orchestration` 스킬 2종의 설치 완료 출력을 받았습니다. 아래 수량은 이전 조사 시점 값으로 보존하며 단순 합산하지 않습니다. [설치 근거와 적용 범위](./orca-remote-server.md#mobile-followup)

> 2026-10-23 읽기 전용 조사. 설치 파일·설정의 선택된 필드·심볼릭 링크·해시와 CLI 목록을 확인했습니다. 스킬 본문은 비교 자료로만 읽었으며 워크플로·helper·MCP 도구는 실행하지 않았습니다. 조사 단계에서는 설치·업데이트·삭제·설정 변경·커밋·push를 하지 않았습니다. 후속 문서 검토·커밋·게시와 조사 단계의 실행 범위를 구분합니다. 아래 호출 예시는 향후 사용을 위한 것이며 이번 실행 결과가 아닙니다.

서버 접속·Orca 작업 공간 사용법은 [기존 사용 가이드](./usage-guide.md), 날짜별 설치·실행 근거는 [환경 점검 기록](./evidence.md)에 둡니다. 이 문서는 **어떤 확장을 선택하고 두 CLI에서 어떻게 구분해 사용하는지**를 다룹니다. 실제 계정·호스트·네트워크 주소·서비스 포트·인증정보는 기록하지 않습니다. `~/`는 사용자 홈을 일반화한 표기입니다.

## 확인 수준을 읽는 법

| 구분 | 의미 | 이번 조사에서의 한계 |
|---|---|---|
| 설치 파일 있음 | SKILL.md·플러그인 파일·실행 파일이 존재 | 의존성·인증·동작 성공을 의미하지 않음 |
| 활성 설정 | 설정이나 목록의 enabled 값 확인 | 실제 서버 연결·도구 호출 성공과 구분 |
| CLI 인식 | CLI 목록에 표시 | 모든 스킬이 개별 인식되는지까지 일괄 확인하지 않음 |
| 실행 확인 | 해당 기능의 실제 결과가 있음 | 이번에는 실행 시험 없음. 과거 근거는 날짜·출처를 함께 표시 |

`claude plugin list --json`과 `codex mcp list --json`만 목록 조회로 실행했습니다. 출력은 이름·버전·활성 여부·인증 상태만 추렸고 URL·토큰·환경 변수 값은 출력하지 않았습니다. `claude mcp list`를 통한 연결 확인, 실제 MCP 호출, 에이전트·스킬 실행은 하지 않았습니다.

## 설치 위치와 중복 계산

PATH의 실행 파일을 해석한 결과 Claude는 `~/.local/share/claude/versions/2.1.308`, Codex는 `~/.codex/packages/standalone/releases/0.163.0-x86_64-unknown-linux-musl/bin/codex`를 가리켰습니다. 버전 출력·모델 작업을 다시 실행한 결과와 구분합니다.

| 위치 | 직접 확인한 내용 | 계산·해석 |
|---|---|---|
| `~/.agents/skills/<skill>/SKILL.md` | 공용 원본 142개, 디렉터리 링크 0개 | 양쪽에서 쓰는 원본. 142개 전부의 실행 성공은 아님 |
| `~/.claude/skills/<skill>/SKILL.md` | 직속 스킬 137개: 공용 원본 링크 134개 + ECC 별도 사본 3개 | 링크 134개는 공용 원본과 같은 실파일이므로 추가 설치 134개로 합산하지 않음. 깨진 링크 0개 |
| `~/.claude/skills/synced/<sync-bucket>/…/SKILL.md` | 하위 스킬 파일 13개 | 직속 137개와 별도 계층. 동기화 경로 존재만 확인, 현재 CLI 노출·우선순위·동기화 주체는 미확인 |
| `~/.claude/plugins/cache/<marketplace>/<plugin>/<revision>/` | Claude 설치 레지스트리가 지정한 플러그인 사본 | 과거 캐시 전체를 현재 활성 설치 수로 세지 않음 |
| `~/.claude/agents/ecc-<role>.md` | 전문 에이전트 4개 + 출처 파일 4개 | 스킬 4개가 아님. Claude 전용 에이전트 정의 |
| `~/.codex/skills/.system/<skill>/SKILL.md` | 시스템 스킬 5개 | `imagegen`, `openai-docs`, `review-agent`, `skill-creator`, `skill-installer`. 파일 존재와 세션 노출은 구분 |
| `~/.codex/plugins/cache/openai-curated-remote/<plugin>/<revision>/` | 플러그인 10종의 캐시 디렉터리 | 캐시만으로 활성·계정 연결·현재 CLI 인식을 단정하지 않음 |

공용 원본 142개는 lock에 기록된 **K-skill 130 + find-skills 1 + Orca 3**과, lock에 없는 **문서 4 + Anthropic skill-creator 1 + ECC 3**으로 나뉩니다. lock은 `~/.agents/.skill-lock.json`의 출처 기록이며 활성 목록이 아닙니다.

공용 `docx`·`pdf`·`pptx`·`xlsx`·`anthropic-skill-creator`는 Claude 직속 링크가 없습니다. Claude는 문서·제작 플러그인 쪽에 대응 스킬을 갖고 있습니다. 문서 4종의 SKILL.md는 공용 사본과 현재 Claude 문서 플러그인 사본의 바이트가 같지만, 서로 다른 파일이며 전체 보조 파일까지 동일하다고 검사한 것은 아닙니다. 이름·메뉴·Orca selector 수를 합쳐 고유 스킬 총수로 표시하지 않습니다.

Claude `synced`에는 `built-in-browser`, `chrome-browser`, `computer-use`, `deep-research`, `docs`, `docx`, `google-workspace`, `import-memory`, `morning`, `pdf`, `pptx`, `skill-creator`, `xlsx`가 있습니다. 브라우저·화면 제어·Google 연동 등은 해당 앱과 연결 도구가 있어야 하는 설명을 포함합니다. 파일만으로 SER8의 헤드리스 셸에서 사용할 수 있다고 보지 않습니다. 같은 이름의 공용 `computer-use`는 **Orca용**이고 synced 사본은 **Claude 앱용**입니다. 이번에는 선택·호출하지 않았습니다.

## Superpowers에서 고르는 단계

양쪽 캐시에 아래 15개 이름의 스킬 파일이 있습니다. 역할 표는 설치 설명을 기준으로 한 선택 안내이고, 이번 실행 확인이 아닙니다. Claude 7.0.0과 Codex 6.4.2의 세부 절차가 모두 같다고 가정하지 않습니다. 요청 예시는 `superpowers:writing-plans로 이 요구사항의 작업 계획을 정리해줘`처럼 단계와 범위를 함께 지정합니다.

| 이름 | 언제 쓰는가 |
|---|---|
| `using-superpowers` | 세션에서 적용할 작업 절차를 확인할 때 |
| `brainstorming` | 기능·구성 변경 전 목표와 선택지를 정리할 때 |
| `writing-plans` | 여러 단계 요구사항을 구현 계획으로 나눌 때 |
| `executing-plans` | 합의된 계획을 직접 실행할 때 |
| `systematic-debugging` | 오류 원인과 재현 근거를 조사할 때 |
| `test-driven-development` | 기능·버그 수정에 필요한 테스트 흐름을 정할 때 |
| `using-git-worktrees` | 별도 작업 디렉터리·브랜치 격리가 필요할 때 |
| `requesting-code-review`, `receiving-code-review` | 검토를 요청하거나 받은 피드백을 평가할 때 |
| `verification-before-completion` | 완료 주장 전에 실제 검증 결과를 확인할 때 |
| `finishing-a-development-branch` | 구현·검증 후 통합 방법을 결정할 때 |
| `subagent-driven-development`, `dispatching-parallel-agents` | 사용자와 프로젝트가 허용한 병렬 작업·위임이 필요할 때. 이 저장소의 순차 사용 원칙과 구분 |
| `writing-skills` | 스킬 지침을 제작·개선할 때 |
| `diagnosing-superpowers` | 절차 적용이 반복·누락된 원인을 돌아볼 때 |

## 플러그인과 MCP의 실제 상태

### Claude

설정은 `~/.claude/settings.json`의 enabledPlugins, 설치 레지스트리는 `~/.claude/plugins/installed_plugins.json`을 읽었습니다. 아래 4개는 CLI 목록과 일치합니다.

| 플러그인 | 설치 revision | 활성·CLI 인식 | 역할·사용 시점 |
|---|---|---|---|
| `superpowers@claude-plugins-official` | `7.0.0` | 활성, 목록 표시 | 작업 이해·계획·디버깅·구현·검토·완료 검증의 기본 흐름 |
| `document-skills@anthropic-agent-skills` | `dbd4588f9e10` | 활성, 목록 표시 | 문서·슬라이드·표·디자인 등 해당 결과물이 필요할 때 |
| `skill-creator@claude-plugins-official` | `af59ee3a1051` | 활성, 목록 표시 | 새 스킬을 만들거나 평가·개선할 때 |
| `github@claude-plugins-official` | `af59ee3a1051` | **비활성**, 목록 표시 | 사용하지 않음. GitHub 작업은 기존 인증된 git·gh 사용 |

문서 플러그인은 docx·pdf·pptx·xlsx 외에도 `brand-guidelines`, `internal-comms`, `claude-api`, `webapp-testing`, `academy-guide`, `algorithmic-art`, `skill-creator`, `web-artifacts-builder`, `discernment-nudge`, `mcp-builder`, `canvas-design`, `doc-coauthoring`, `slack-gif-creator`, `frontend-design`, `theme-factory`를 포함합니다. 이는 파일 목록이며 모두 실행 확인된 도구 목록은 아닙니다. 아래처럼 필요할 때만 선택합니다.

| 작업 | 선택할 항목·요청 예시 | 의존성·현재 한계 |
|---|---|---|
| Word·PDF·PPT·Excel | `docx로 보고서 초안을 만들어줘`, `pdf로 표를 추출해줘`, `pptx로 발표 자료를 만들어줘`, `xlsx로 계산표를 만들어줘` | 아래 문서 의존성 절 참고. 생성·렌더링 시험 미실시 |
| 공동 문서 초안·내부 안내 | `doc-coauthoring으로 요구사항 초안을 정리해줘`, `internal-comms로 내부 공지 초안을 작성해줘` | 필요한 원문·수신 대상·공개 범위 확인. 이번에는 외부 전송 안 함 |
| 시각 디자인·테마 | `frontend-design`, `web-artifacts-builder`, `canvas-design`, `algorithmic-art`, `theme-factory`, `brand-guidelines`, `slack-gif-creator`를 이름으로 지정하고 산출물 요청 | Node·브라우저·렌더링 등 해당 스킬의 실제 의존성은 개별 미검증 |
| 웹 앱 검사 | `webapp-testing으로 이 앱의 검사 계획을 정리해줘` | 실제 검사에는 브라우저·대상 앱 등이 필요. 이 조사에서 실행 안 함 |
| Claude API·MCP 서버 제작 | `claude-api로 연동 방법을 설명해줘`, `mcp-builder로 서버 설계를 검토해줘` | API 호출은 별도 자격 증명·개발 의존성이 필요할 수 있음. 설치 파일만 확인 |
| 학습 안내·판단 보조 | `academy-guide`, `discernment-nudge`의 본문을 먼저 확인하고 해당 목적일 때 선택 | 파일 존재만 확인, 개별 동작·호출 경로 미검증 |

제작 스킬은 문서 플러그인의 `skill-creator`와 전용 제작 플러그인 양쪽에 있습니다. 이름만으로 어느 파일이 선택됐는지 단정하지 않고 세션의 이름 공간·자동완성·사용 경로를 확인합니다. 공용 `anthropic-skill-creator` 및 Codex 시스템 `skill-creator`와도 구분합니다.

### Codex

사용자 설정 `~/.codex/config.toml`에는 이번 확인 범위에서 plugins 섹션이 없습니다. 이것만으로 앱·계정 기반 플러그인이 비활성이라고 판단하지 않습니다. 다음은 **디스크의 캐시 존재**만 확인한 목록이며, 이 Codex 조사 세션에 노출된 일부 스킬·도구를 별도 근거로 삼을 수 있어도 모든 SER8 CLI 세션의 활성·인식을 보장하지 않습니다.

| 플러그인 캐시 | revision | 역할·향후 요청 예시 | 별도 조건 |
|---|---|---|---|
| `superpowers` | `6.4.2` | `superpowers:systematic-debugging으로 원인을 조사해줘` | Claude의 7.0.0과 다른 버전, 파일을 서로 덮어쓰지 않음 |
| `codex-security` | `0.1.32` | `codex-security:security-diff-scan으로 이 diff를 검토해줘` | 보안 감사·수정·검증 등 15종 파일. 각 작업 범위·권한·도구 연결은 별도 |
| `notion` | `3.0.1` | `notion:notion-research-documentation으로 관련 자료를 정리해줘` | 조사·회의·주간 보고·DB 설계·명세 작업 5종. Notion 계정·워크스페이스 권한 필요 |
| `sites` | `1.1.1` | `sites:sites로 웹사이트 초안을 만들어줘` | 제작·remix 2종. 계정 연결·배포 권한 별도 확인 |
| `work-pets` | `0.1.6` | `work-pets:pets로 사용 가능한 펫을 보여줘` | 조회·생성·수정 3종. 해당 제품 환경·서비스 연결 필요 |
| `plugin-management` | `0.1.0` | `plugin-management:plugin-management로 필요한 연결을 확인해줘` | 연결·설정 관리용. 설치·삭제 권한을 포괄 부여하는 요청으로 보지 않음 |
| `openai-templates` | `0.1.1` | 예: `artifact-template-system-design` 파일을 확인해 시스템 설계 문서 양식 선택 | 문서·운영·재무 등 20종 파일, 현재 세션 인식·렌더링 미확인 |
| `github` | `0.1.12-5f7cd798dc99` | `연결된 GitHub에서 저장소 정보를 조회해줘` | 계정 커넥터. 과거 조회 성공 보고와 현재 연결은 구분 |
| `gmail` | `0.1.10` | `연결된 Gmail에서 지정한 메일을 찾아줘` | 계정·메일 권한 필요, 현재 연결 미검증 |
| `canva` | `17.0.1` | `연결된 Canva에서 발표 자료를 찾아줘` | 계정·디자인 권한 필요, 현재 연결 미검증 |

플러그인 캐시는 CLI 패키지·공용 스킬과 설치 단위가 다릅니다. `github`·`gmail`·`canva`에는 위 검사 위치의 `skills/*/SKILL.md`가 없었으며, 도구를 제공하는 플러그인을 스킬 0개라는 이유로 미설치로 취급하지 않습니다.

### MCP와 인증

| 대상 | 설정·목록 확인 | 실제 사용 근거·한계 |
|---|---|---|
| Claude Context7 | `~/.claude.json`에 HTTP 방식 `context7` 등록 | 2026-10-21 Claude 세션의 Python logging 문서 조회 성공 기록. 이번에는 연결·호출·인증 시험 안 함 |
| Codex Context7 | `~/.codex/config.toml`에 등록. `codex mcp list --json`: enabled=true, auth_status=`not_logged_in` | CLI 인식·활성 확인. 인증 상태 표시만으로 사용 불가·공개 조회 가능을 단정하지 않음. 실제 조회 미검증 |
| Claude GitHub | 플러그인 `.mcp.json`에 정의가 있어도 플러그인은 비활성 | git·gh 사용 결정 유지. 과거 MCP 성공을 현재 사용으로 바꾸지 않음 |
| Codex 계정 커넥터·플러그인 MCP | Notion·codex-security의 캐시에 MCP 정의 존재 | 사용자 config의 Context7과 별개. 연결·도구 사용 가능 여부를 이번에 시험하지 않음 |

이 저장소에는 `.mcp.json`, `.claude/settings.json`, `.claude/settings.local.json`, `.codex/config.toml`이 없고, Claude 사용자 설정의 이 저장소 항목에 별도 MCP 등록·비활성 목록은 없습니다. 다른 프로젝트 설정은 조사하지 않았습니다. 설정의 URL·실행 인자·헤더 값과 인증 파일은 공개하지 않았습니다.

## ECC 3종: 의도와 실제 차이

설치 출처 파일 `.install-source`는 양쪽 모두 `affaan-m/ECC`, commit `90606c8`, version `2.2.3`, 설치일 `2026-10-21`을 가리킵니다. 설치 의도는 기존 보고의 **선택 스킬 3개 + Claude 전문 에이전트 4개, 명시 요청 때만 사용, Superpowers 우선**과 일치합니다. 전체 ECC 도입이나 Hooks·전역 규칙·추가 MCP 도입 기록이 아닙니다. 이번 변경의 작성자·세부 수정 시점·최초 설치 후 변경 경위까지 출처 파일만으로 확정하지 않습니다.

비교 기준은 공용 `~/.agents/skills/ecc-<name>/`와 Claude `~/.claude/skills/ecc-<name>/`의 파일 전체 목록 및 SKILL.md unified diff입니다. 세 SKILL.md 모두 SHA-256이 다릅니다.

| 스킬·파일 | 확인한 차이 | 의미 |
|---|---|---|
| `ecc-security-review/SKILL.md` | 공용 495행, Claude 512행. Claude에는 `metadata.origin: ECC`, `disable-model-invocation: true`; 공용의 `license: MIT` 필드는 없음 | Claude 사본의 자동 호출 제한 메타데이터와 공용 사본의 표기가 다름. 단순 중복으로 보지 않음 |
| 같은 파일의 입력 검증 예시 | 공용 `error.errors`, Claude `error.issues` | 예시 코드가 다름. 이번에 라이브러리 동작·호환성 시험은 하지 않음 |
| 같은 파일의 raw SQL 예시 | 공용은 PostgreSQL 숫자 placeholder, Claude는 `?`와 드라이버별 문법 설명·주석 추가 | Claude 주석은 달러+숫자가 스킬 인자로 치환돼 SQL 예시를 훼손할 수 있어 피한다고 설명함. 이 설명이 의도에 대한 파일 내부 근거이며 실제 재현 시험은 안 함 |
| 같은 파일의 CSP 예시 | Claude는 unsafe-inline·unsafe-eval 기본값을 빼고 엄격한 정책 설명과 base-uri·object-src·frame-ancestors 추가 | 보안 검토 예시 자체가 보완된 별도 사본. 적용·배포 검증 결과는 아님 |
| `ecc-security-review/cloud-infrastructure-security.md` | Claude에만 있음 | IAM·비밀 관리·네트워크·CI/CD·백업 등 클라우드 검토 참고 문서 |
| `ecc-architecture-decision-records/SKILL.md` | Claude에 `disable-model-invocation: true` 한 줄 추가. 나머지 본문 같음 | ADR 기록 방법은 같고 호출 제어 메타데이터가 다름 |
| `ecc-context-and-decisions/SKILL.md` | Claude에 `disable-model-invocation: true` 한 줄 추가. 나머지 본문 같음 | 도메인 용어·맥락과 ADR 분리 방법은 같음 |
| `ecc-context-and-decisions/templates/context.example.md` | 양쪽 바이트 동일 | 별도 사본이지만 템플릿 내용은 같음 |
| 각 스킬의 `agents/openai.yaml` | 공용에만 있으며 모두 `allow_implicit_invocation: false` | Codex 쪽 명시 호출 정책을 표현하는 메타데이터. 이번 개별 세션 로드 여부는 미검증 |
| `.install-source` | ADR은 동일. security-review·context-and-decisions는 공용 출처 경로가 `.agents/skills/…`, Claude는 `skills/…` | 같은 commit이어도 가져온 upstream 경로가 다름 |

공용 security-review·context-and-decisions의 openai.yaml 기본 프롬프트와 context 스킬 본문에는 일부 **접두사 없는 원래 이름**이 남아 있습니다. 자동 연결이 올바른 ECC 사본을 찾는지는 미검증입니다. 실제 사용할 때 `ecc-`가 붙은 설치 이름을 명시하고 선택 경로를 확인합니다. 이번에는 수정하지 않았습니다.

### Superpowers와 겹치는 부분과 사용 구분

| 목적 | 기본 흐름 | ECC를 추가로 요청할 때 |
|---|---|---|
| 작업 계획·구현·디버깅·완료 확인 | Superpowers의 해당 절차 | 같은 작업에서 두 계획·검토 흐름을 자동 중첩하지 않음 |
| 코드 검토·보안 | Superpowers 검토 단계와 범위에 맞는 검증 | 보안 체크리스트를 명시 요청할 때 `ecc-security-review`; 전문 검토가 필요하면 Claude `ecc-security-reviewer` 또는 `ecc-code-reviewer`를 별도로 지정 |
| 기술 선택의 이유 보존 | 작업 계획에 현재 선택과 이유 정리 | 오래 유지할 결정은 `ecc-architecture-decision-records`로 ADR 정리. 기존 ADR 위치·형식 재사용 |
| 도메인 용어 정리 | 기존 프로젝트 문서와 지침 우선 | 반복해서 혼동되는 용어가 있으면 `ecc-context-and-decisions`. 기존 용어집 재사용, 일정·현재 작업 상태를 CONTEXT.md에 복제하지 않음 |
| 빌드·DB 문제 | Superpowers로 원인 조사 | Claude 전문 에이전트 `ecc-build-error-resolver`, `ecc-database-reviewer`를 명시 요청할 때만 추가 |

Claude 에이전트 4개는 Sonnet 및 도구 목록이 정의된 파일이며, 현재 Claude 세션의 에이전트 메뉴 인식·실행은 미검증입니다. Codex 대응 에이전트 설치는 기존 보류 결정을 유지합니다. 사용자 설정의 hook 이벤트는 존재하며 Claude hook 본문에서 Orca 참조를 확인했습니다. 읽은 사용자 hook 설정에는 ECC 문자열이 없었지만, 이것을 모든 플러그인·프로젝트의 Hooks 부재로 확대하지 않습니다.

## 실제 선택·호출 순서

1. SER8 원격 작업 공간·브랜치·프로젝트 지침을 확인합니다. Claude와 Codex는 같은 프로젝트에서 순차 사용합니다. YOLO 유지 결정은 변경하지 않으며 프로젝트의 작업 제한은 계속 적용합니다.
2. 할 일을 자연어로 설명하고 기본 작업 흐름은 Superpowers를 따릅니다. 예: `이 오류를 systematic-debugging 절차로 조사하고 근거부터 정리해줘`.
3. 결과물이 정해지면 해당 도구 하나를 선택합니다. 문서면 docx·pdf·pptx·xlsx, 라이브러리 문서면 Context7, 한국 서비스 조회면 해당 K-skill을 선택합니다.
4. ECC가 필요하면 아래처럼 이름과 범위를 명시합니다. 파일 존재만 확인한 항목은 CLI의 자동완성·스킬 목록에서 이름과 로드 경로를 확인한 뒤 사용합니다. 이번에는 이 단계의 호출 시험을 하지 않았습니다.
5. 실행 결과·실행하지 않은 항목을 구분하고 diff를 검토합니다. 사용 권한·설치 여부가 불분명하면 그 상태를 먼저 보고하며 자동 설치·인증 설정 변경으로 메우지 않습니다.

| 작업 | Claude 요청·호출 예시 | Codex 요청·호출 예시 |
|---|---|---|
| 보안 체크리스트 | `/ecc-security-review` 뒤에 `지정한 diff만 읽기 전용 검토` | `$ecc-security-review`를 명시하고 같은 범위 요청 |
| ADR 기록 | `/ecc-architecture-decision-records`로 결정 초안 요청 | `$ecc-architecture-decision-records`로 같은 요청 |
| 도메인 맥락 | `/ecc-context-and-decisions`로 기존 용어집 검토 요청 | `$ecc-context-and-decisions`로 같은 요청 |
| 문서 생성 | `document-skills의 docx를 사용해줘`처럼 플러그인 출처까지 지정 | `$docx`, `$pdf`, `$pptx`, `$xlsx`처럼 공용 설치 이름 명시 |
| 스킬 제작 | `전용 skill-creator 플러그인을 사용해줘` | 시스템 `$skill-creator` 또는 `$anthropic-skill-creator` 중 목적·출처를 지정 |
| 라이브러리 문서 | `Context7로 이 버전의 공식 사용법을 찾아줘` | 같은 자연어 요청. 현재 Context7 인증·도달 여부는 호출 전 확인 필요 |
| GitHub | `git·gh로 저장소와 diff를 확인해줘` | 계정 커넥터 조회와 git·gh 작업을 구분해 요청 |
| 한국 서비스 조회 | `korea-weather 스킬로 지정 지역 날씨를 조회해줘` | `$korea-weather`처럼 설치 이름과 조회 조건 지정 |

slash·달러 예시는 설치된 이름을 명시하는 사용 예시이며, 모든 현재 세션의 자동완성 노출·중복 이름 선택을 실행으로 보장한 것은 아닙니다. 플러그인 이름 공간이 표시되면 그 이름으로 선택합니다. 보안 검토 스킬과 전문 에이전트는 서로 다른 항목입니다. 이번 문서 작성은 ECC 워크플로를 실행하거나 에이전트를 호출한 작업이 아닙니다.

## 기본 사용·필요할 때 사용·비활성 상태

| 구분 | 도구 | 사용 목적·예시 | 의존성·인증 |
|---|---|---|---|
| 기본 | Superpowers | 작업 이해→계획→조사·구현→검토→검증 중 필요한 단계 | 외부 업무용 API 키를 일괄 요구하는 도구가 아님. 모델 실행 계정은 별도 |
| 기본 | git·gh | 변경·저장소 조회. Claude GitHub MCP 대신 사용 | 기존 gh 인증은 과거 확인됨. 토큰 출력 안 함 |
| 필요할 때 | Context7 | 라이브러리·버전 문서 검색 | MCP 연결·서비스 인증·한도는 개별 확인, Codex 현재 조회 미검증 |
| 필요할 때 | 문서 4종 | docx·pdf·pptx·xlsx 결과물 | 아래 의존성 참고 |
| 필요할 때 | `find-skills` | `find-skills로 필요한 기능의 후보만 찾아줘. 설치는 하지 마` | Node·네트워크·Skills CLI. 검색도 미실행, npx가 패키지를 받을 수 있어 이번에는 사용 안 함 |
| 필요할 때 | `orca-cli` | `orca-cli로 현재 작업 공간을 읽기 전용 확인해줘` | 실행 중인 Orca·해당 세션 CLI. 외부 Linux 셸의 bare orca는 화면 낭독기일 수 있음 |
| 별도 요청 시 | `computer-use`, `orchestration` | Orca GUI 제어 또는 감독하는 다중 작업 조정 | 화면·권한·실제 Orca 런타임 필요. 헤드리스 설치만으로 GUI 가능하다고 판단 안 함. 순차 사용이 기본 |
| 명시 요청 시 | ECC 3종·Claude 전문 에이전트 4개 | 위 비교·호출 표 참고 | 설치·메타데이터 확인, 실제 실행은 미검증 |
| 필요할 때 | Codex 시스템 `imagegen`, `openai-docs`, `review-agent` | 이미지 생성, OpenAI 사용법 확인, 검토 도우미를 해당 설치 설명에 따라 선택 | 파일 존재 확인. 서비스·세션 도구·에이전트 지원 여부는 별도, 이번 실행 없음 |
| 별도 요청 시 | Codex 시스템 `skill-installer` | 설치 후보와 출처 검토 | 설치 기능은 이번 범위 밖, 호출 안 함 |
| 필요할 때 | K-skill 130종 | 아래 분야별 목록에서 해당 작업만 선택 | 개별 서비스 계정·키·보조 도구는 미검증 |
| 비활성 | Claude GitHub MCP | git·gh 사용 | 비활성 유지 |
| 제외 | agent-browser | 다시 설치·활성화하지 않음 | 공용·Claude 직속 스킬 이름에 없음. 다른 browser 스킬 파일과 혼동하지 않음 |
| 보류 | handoff | 출처 미확인 상태 유지 | 공용·Claude 직속 스킬 이름에 없음. Orca 문서의 handoff 기능 설명과 독립 설치 항목을 구분 |
| 보류 | Codex ECC 전문 에이전트 대응 | Claude 정의를 자동 복사하지 않음 | 기존 선택 유지 |

### 문서와 외부 서비스의 의존성

- docx 신규 작성 지침은 Node `docx`, pptx는 `pptxgenjs`를 사용합니다. Python 문서 패키지 import 성공 기록만으로 이 Node 패키지까지 준비됐다고 판단하지 않습니다. 이번에는 import·require·생성 시험을 하지 않았습니다.
- pdf는 pypdf·pdfplumber·reportlab 등, xlsx는 openpyxl·pandas 및 필요 시 재계산 도구를 사용합니다. 과거 사용자 설치 보고에는 Python 가상환경의 관련 모듈 import와 LibreOffice·pandoc·qpdf 실행 성공이 있습니다. 현재 스킬이 그 가상환경을 사용하는지는 미검증입니다.
- 이번에는 LibreOffice·pandoc·qpdf·pdftoppm·tesseract 실행 파일의 PATH 해석만 확인했습니다. 렌더링·OCR·한글 폰트·문서 품질·파일 생성 성공을 시험하지 않았습니다.
- K-skill의 SKILL.md는 상당수가 `npx -y @nomadamas/k-skill@0 instruct <skill>`로 본 지침을 받는 stub입니다. 파일 개수는 전체 실행 환경 준비 수가 아닙니다. 이 명령은 패키지 다운로드·캐시 쓰기가 생길 수 있어 이번에는 실행하지 않았습니다.
- `k-dart` 설명에는 사용자 API 키가, `toss-investment`에는 공식 OAuth2 자격 증명이 명시돼 있습니다. 네이버 광고·팝빌·채용 기업회원·등기 등도 서비스별 인증·권한 또는 로그인이 필요한 기능이 있으나 현재 계정·키 보유 여부는 조사하지 않았습니다. `naver-blog-research`는 설명상 Python 표준 라이브러리·API 키 불필요이며 실제 조회는 미검증입니다.
- `hwp`는 kordoc, `rhwp-edit`는 k-skill-rhwp·WASM, `rhwp-advanced`는 rhwp Rust CLI를 안내합니다. 공용 Python 문서 패키지 설치와 별개이며 해당 보조 도구는 이번에 검사·실행하지 않았습니다.
- Notion·Gmail·Canva·GitHub 같은 계정 연동과 로컬 스킬·MCP 등록은 별개입니다. 필요한 서비스의 인증·권한을 확인한 후 요청한 기능만 사용합니다. 인증 파일이나 환경 변수 전체를 출력하지 않습니다.

## 남은 미확인 항목

- Claude의 개별 스킬·ECC 에이전트 인식과 중복 이름 선택 우선순위. synced 13개가 현재 CLI에 어떻게 노출되는지와 그 동기화 주체.
- Codex의 캐시 10종 전체에 대한 활성·CLI 인식·계정 연결. 시스템 `review-agent`와 ECC 3종의 현재 세션 노출 여부.
- Codex Context7의 실제 연결·조회 및 인증 요구 방식. 목록의 not_logged_in 표시만 확인한 상태.
- ECC 차이의 작성자·세부 수정 시점, SQL 인자 치환 현상의 재현, 접두사 없는 내부 참조가 현재 이름으로 연결되는지.
- Node 문서 패키지, 실제 Python 가상환경 선택, 한글 렌더링·OCR·문서 생성과 각 K-skill의 외부 계정·보조 도구 동작.
- handoff 원본 출처. agent-browser 제외·Claude GitHub MCP 비활성·ECC 명시 호출·YOLO 유지 결정은 변경하지 않음.

## K-skill 분야별 선택 목록

아래는 lock의 K-skill 130종을 설치된 SKILL.md의 category·description으로 분류한 색인입니다. 각 항목은 **설치 파일 확인 / 개별 활성·CLI 인식·실행·인증 미검증**이며, 공용 원본과 Claude 링크를 중복 계산하지 않았습니다. 역할은 설치 설명을 요약했고 세부 조건은 실제 사용 시 해당 본문에서 확인합니다. 호출은 Claude에서 이름을 자연어로 지정하고 Codex에서는 `$<skill-name>` 형식을 사용합니다. 이 색인은 별도 설치 권유나 실행 확인 목록이 아닙니다.

| 분야 | 설치 이름 | 역할·선택할 때 |
|---|---|---|
| automotive | `daangn-cars-search` | 당근중고차 공개 차량 매물 검색 |
| business | `biz-health-check` | 사업자번호로 등록 상태·가입 사업장·체납·제재·인허가 자료 대조 |
| business | `fsc-corporate-info` | 금융위원회 기업기본정보(법인 개요)를 공공데이터포털 API(k-skill-proxy 경유)로 조회한다. |
| business | `g2b-order-plan-search` | 조달청 나라장터 발주계획현황서비스로 물품·공사·용역·외자 발주계획 목록을 검색한다. |
| business | `g2b-sanctioned-supplier` | 조달청 나라장터 부정당제재업체정보를 공공데이터포털 API(k-skill-proxy 경유)로 조회한다. |
| business | `kstartup-search` | 공공데이터포털 창업진흥원 K-Startup Open API(15125364)로 통합 공고 사업 정보·지원사업 공고·창업 콘텐츠·통계보고서를 k-skill-proxy 경유로 조회한다. |
| business | `localdata-business-status` | 지방행정 인허가데이터(LOCALDATA)로 동네 사업장(식당·카페·숙박·약국·미용실·학원 등 인허가 업종 208종)의 영업/휴업/폐업 상태, 인허가일자(업력), 폐업일자, 업태, 주소를 조회한다. |
| business | `national-pension-workplace` | 국민연금공단 국민연금 가입 사업장 내역을 공공데이터포털 API(k-skill-proxy 경유)로 조회한다. |
| business | `nts-business-registration` | 국세청 사업자등록정보 진위확인 및 사업자등록 상태조회를 공공데이터포털 API(k-skill-proxy 경유)로 수행한다. |
| business | `nts-tax-delinquency` | 국세청 고액·상습체납자 명단공개를 nts.go.kr 공개 검색으로 조회한다. |
| business | `popbill` | 팝빌 전자세금계산서·전자명세서·현금영수증·문자·카카오톡·팩스·휴폐업/기업정보·계좌조회·홈택스 수집을 테스트/운영 환경에서 안전하게 호출한다. |
| business | `store-longevity-radar` | 상가 데이터의 과거·현재 점포를 비교해 장수 점포 후보 추출 |
| civic | `assembly-bill-vote-search` | 열린국회정보 Open API를 k-skill-proxy 경유로 호출해 의안 검색·상세와 국회의원 본회의 표결정보를 조회한다. |
| civic | `gov-overseas-trip-report` | 선관위·권익위·정보공개포털·주요 지방의회 등 검증된 공개 표면에서 공무국외출장/국외훈련 보고서·현황을 조회하고, 첨부 원문이 있으면 kordoc으로 사실·공개성·검토 신호만 구조화한다. |
| civic | `sharenuri-facility-search` | 공유누리 공공시설·물품 검색과 요금·정원·예약 방법 확인 |
| consumer | `consumer-price-safety-search` | 참가격·물품·리콜 조회용 초안. 서비스 인증키·메뉴 매핑 미검증 |
| convenience | `parking-lot-search` | 위치를 확인한 뒤 주변 공영주차장 조회 |
| convenience | `public-restroom-nearby` | 위치를 확인한 뒤 주변 공공·개방 화장실 조회 |
| culture | `kopis-performance-search` | KOPIS 공연 목록·상세·시설을 조회한다. |
| data | `bok-ecos-stats` | 한국은행 ECOS Open API로 기준금리, 환율, 소비자물가지수, 통화량 등 중앙은행 경제통계 시계열과 100대 핵심지표를 조회한다. |
| data | `kosis-stats` | 국가데이터처가 운영하는 KOSIS(국가통계포털, kosis.kr) Open API로 한국 공식 통계표를 검색하고 메타데이터·데이터·대용량 자료를 조회한다. |
| documents | `hwp` | kordoc으로 HWP·HWPX 읽기·구조 추출·변환 |
| documents | `rhwp-advanced` | rhwp로 HWP 레이아웃·IR·썸네일·문서 차이 분석 |
| documents | `rhwp-edit` | k-skill-rhwp로 HWP 텍스트·표·셀 편집 |
| education | `korean-scholarship-search` | 공식 장학금 공고에서 지원 조건·금액 검색 |
| entertainment | `korean-cinema-search` | CGV, 메가박스, 롯데시네마 영화관 검색, 상영작, 시간표, 잔여석 조회가 필요할 때 사용한다. |
| finance | `company-analysis` | 국내·해외 상장기업의 공개 공시와 실적발표를 대조해 3대 재무제표의 변화, 사업·경쟁구도, 주요 일정과 조회 시점 주가를 여섯 섹션의 한국어 채팅 분석으로 정리한다. |
| finance | `daishin-report-search` | 대신증권 리포트 GitHub Pages 미러에서 최신 HTML 리포트 목록과 원문/설명 페이지를 조회한다. |
| finance | `government-bond-analysis` | 한국·미국 국채시장을 공식 금리 데이터로 분석하고 커브 변화, 한·미 금리차, 확인된 국채 입찰·통화정책 일정을 같은 형식으로 정리한다. |
| finance | `k-dart` | 금융감독원 전자공시시스템(DART) OpenAPI로 공시검색, 기업개황, 재무제표, 주요사항보고서를 조회한다. |
| finance | `korean-bond-search` | 국내 채권 발행조건·잔액·옵션·전환 관련 조건 검색·비교 |
| finance | `korean-jangbu-for` | 한국 사업자 장부·세무 자료·계정과목·전달용 CSV 정리 |
| finance | `korean-stock-search` | 국내 상장 종목·기본정보·일별 거래 조회 |
| finance | `market-event-impact` | 시장 사건의 변화·자산 간 전달 경로·관련 근거 분석 |
| finance | `multi-asset-morning-briefing` | 글로벌 주식·금리·외환·원자재·변동성과 한국시장 전달 경로를 연결해 근거 링크가 있는 7개 섹션의 멀티에셋 모닝 브리핑을 작성한다. |
| finance | `toss-investment` | 토스증권 공식 Open API(OAuth2)로 계좌, 보유주식, 시세/종목/시장정보, 주문조회를 안전한 read-only 흐름으로 조회한다. |
| food | `bccard-eatpl-search` | 대한민국 맛집, 음식점, 식당, 밥집, 카페, 커피, 디저트, 고깃집, 회식 장소를 지역·역·동네 기준으로 찾아 준다. |
| food | `hola-poke-yeoksam` | 올라포케 역삼점의 메뉴·매장 정보·이벤트 참여 흐름을 remote MCP 서버 기준으로 안내한다. |
| food | `kakao-bar-nearby` | 위치를 확인한 뒤 근처 술집 검색 |
| food | `kamis-food-price` | KAMIS 농수축산물 유통 Open API를 k-skill-proxy 경유로 호출해 부류별 도소매 가격과 전일·주간·월간·연간 비교값을 조회한다. |
| health | `animal-pharmacy-search` | 홍익메디케어 공개 MCP 서버로 지역별 동물약국 목록, 동물용의약품 검색, 최근 6개월 구매 이력 기반 취급 약국을 조회한다. |
| health | `emergency-room-beds` | 위치 주변 응급실·병상 현황 조회 |
| healthcare | `nhis-care-checkup-search` | 장기요양기관·건강검진기관 조회 |
| history | `joseon-sillok-search` | 키워드·왕·연도로 조선왕조실록 검색 |
| history | `korean-heritage-search` | 국가유산 기록·위치·월별 행사 검색 |
| housing | `sh-notice-search` | 서울주택도시개발공사(SH) 공개 공고/공지 게시판에서 청약·주택 공고 목록, 상세 본문, 첨부 미리보기 메타데이터를 직접 조회한다. |
| information | `hankookilbo-news` | 한국일보 헤드라인·기사·주제 검색과 운세 조회 |
| information | `naver-news-search` | 네이버 검색 Open API 뉴스 검색(news.json)을 k-skill-proxy 경유로 조회해 최신 뉴스 기사 제목·발행시각·링크·요약을 보수적으로 정리한다. |
| ip | `korean-patent-search` | KIPRIS 특허·실용신안 검색과 출원번호 상세 조회 |
| jobs | `daangn-jobs-search` | 당근알바 공개 채용공고 검색 |
| legal | `court-payment-order-assistant` | 법원 전자소송 지급명령 신청을 위해 채권자·채무자·청구금액·청구원인·증빙 정보를 인터뷰하고, 신청서 초안과 공식 전자소송 브라우저 입력 handoff를 준비한다. |
| legal | `korean-law-search` | 한국 법령·조문·판례·해석·조례 조회 |
| legal | `korean-privacy-terms` | Next.js 프로젝트의 한국 개인정보처리방침·약관·동의 UI 생성 안내 |
| legal-documents | `corporate-registration-consulting` | 주식회사 발기설립 절차·첨부 HWP 양식·세금 확인 안내 |
| legal-documents | `iros-registry-automation` | 인터넷등기소(IROS)에서 법인/부동산 등기부등본(등기사항증명서) 발급을 준비하고, 사용자가 직접 로그인·결제한 브라우저 흐름 안에서 장바구니·열람·저장을 안전하게 보조한다. |
| lifestyle | `ticket-availability` | YES24 / 인터파크 공연의 공개 일정 + 등급별 잔여석을 단일 HTTP 호출로 조회 (조회 전용, 예매·결제 없음). |
| local-info | `ev-subsidy-status` | 한국 지자체별 전기차 구매보조금 민간공고·접수·출고·출고잔여 대수와 공고 상태를 환경부 무공해차 통합누리집에서 조회한다. |
| logistics | `delivery-tracking` | CJ대한통운·우체국 운송장 배송 조회 |
| marketing | `naver-ad-performance` | 네이버 검색광고(키워드광고)의 노출수·클릭수·광고비·CTR·CPC·전환수를 조회한다. |
| marketplace | `bunjang-search` | 번개장터 검색, 상세조회, 찜, 채팅, 대량 수집, AI TOON export를 bunjang-cli로 안내한다. |
| marketplace | `daangn-used-goods-search` | 당근 중고거래 공개 매물 검색 |
| news | `geeknews-search` | GeekNews public RSS/Atom feed로 긱뉴스 게시물을 조회, 검색, 상세 확인하는 읽기 전용 스킬. |
| other | `government-support-survey` | K-Startup·기업마당·NIPA·KOCCA·SMTECH의 공개 정부지원 공고를 k-skill-proxy로 전수조사하고 프로젝트 적합성을 보수적으로 분류한다. |
| other | `k-skill-cleaner` | 사용 빈도와 사용자 선택을 바탕으로 정리 후보 제안. 삭제는 이번 범위 밖 |
| procurement | `d2b-notice-search` | 국방전자조달시스템(D2B) 공개 입찰공고 검색 화면에서 공고건명·공고구분·공고/개찰일·G2B공고번호·발주기관 조건으로 공고를 조회한다. |
| procurement | `s2b-notice-search` | S2B 학교장터 공개 고객 공고/견적요청 목록을 브라우저 우선으로 조회하고 fixture HTML을 파싱해 공고 메타데이터를 정리한다. |
| public-data | `seoul-weather-risk` | 서울 행정동별 기상 위험 예상 시간대 조회 |
| public-health | `mfds-drug-safety` | 식약처 공공 OpenAPI를 k-skill-proxy 경유로 조회하기 전에 증상·복용상황을 반드시 되묻는 인터뷰형 의약품 안전 체크 스킬. |
| public-health | `mfds-food-safety` | 식약처/식품안전나라 공개 표면을 k-skill-proxy 경유로 조회하기 전에 증상·섭취상황을 반드시 되묻는 인터뷰형 식품 안전 체크 스킬. |
| real-estate | `building-register-search` | 주소·필지로 건축물대장 표제부 조회 |
| real-estate | `court-auction-notice-search` | 법원·기일·지역·가격 조건으로 부동산 매각공고 조회 |
| real-estate | `daangn-realty-search` | 당근부동산 공개 매물 검색 |
| real-estate | `gongsijiga-search` | 필지 단위 개별공시지가 조회 |
| real-estate | `housing-official-price` | 공동주택·개별주택 공시가격 조회 |
| real-estate | `lh-notice-search` | LH 임대·분양·청약 공고 검색 |
| real-estate | `real-estate-search` | 아파트·오피스텔·주택 매매·임대 실거래 조회 |
| recruiting | `job-posting-match` | 한국 구직자의 이력서·경력요약과 희망조건을 바탕으로 잡코리아·사람인 공개 채용공고를 검색하고 적합도와 지원 전략을 정리합니다. |
| recruiting | `jobkorea-talent-search` | 잡코리아 기업회원 로그인 세션으로 유료 열람 전 마스킹된 인재 이력서를 검색·비교해 채용 검토용 shortlist를 만듭니다. |
| recruiting | `saramin-talent-search` | 사람인 기업회원 인재풀 로그인 세션에서 마스킹된 후보 정보를 검색·비교해 유료 열람 전 shortlist를 만듭니다. |
| religion | `religious-facility-search` | 지역·역·랜드마크 주변 종교시설 조회 |
| research | `keris-academic-search` | KERIS RISS 학위논문·학술논문·연구자료 검색 |
| research | `naver-blog-research` | Python 표준 라이브러리로 네이버 블로그 검색·본문 읽기 |
| retail | `coupang-product-search` | k-skill-proxy의 공식 Coupang Partners API 경로로 쿠팡 상품을 검색하고 로켓배송·가격 후보를 비교한다. |
| retail | `daiso-product-search` | 다이소 매장·상품·재고 조회 |
| retail | `danawa-price-search` | 다나와 공개 검색/가격비교 표면으로 상품 후보를 찾고, 쇼핑몰별 최저가·배송비 포함 실구매가·카드 할인가·무이자 할부 정보를 보수적으로 비교한다. |
| retail | `market-kurly-search` | 로그인 없이 접근 가능한 마켓컬리 검색/상품 상세 표면으로 상품 후보, 현재 가격, 할인 여부, 품절 여부를 조회한다. |
| retail | `naver-shopping-search` | 네이버 쇼핑 공개 BFF JSON을 k-skill-proxy로 조회해 상품 후보, 최저가, 판매처 링크를 보수적으로 가격비교한다. |
| retail | `ohou-today-deal` | 오늘의집 공개 오늘의딜 페이지에서 로그인 없이 특가 상품을 조회하고 할인율, 가격, 리뷰, 링크를 정리하는 읽기 전용 스킬. |
| retail | `olive-young-search` | upstream daiso CLI를 사용해 올리브영 매장 검색, 상품 검색, 재고 확인을 조회한다. |
| security | `kr-whois-lookup` | 공공데이터포털 WHOIS 도메인/IP 정보 API를 k-skill-proxy 경유로 호출해 .kr/.한국 도메인, IP 주소, AS 번호의 공개 등록정보를 조회한다. |
| setup | `k-skill-setup` | K-skill 설치·CLI·인증·업데이트 준비 안내. 이번에는 실행하지 않음 |
| sports | `kbl-results` | KBL 한국프로농구 경기 결과와 현재 팀 순위를 날짜/팀 기준으로 조회한다. |
| sports | `kbo-results` | 날짜별 KBO 일정·결과 조회 |
| sports | `kleague-results` | 케이리그 경기 결과와 현재 순위를 날짜/팀 기준으로 조회한다. |
| sports | `korean-marathon-schedule` | 고러닝과 대한철인3종협회 공개 표면으로 한국 마라톤·철인3종 경기 일정, 장소, 신청 마감일, 종목을 조회한다. |
| sports | `lck-analytics` | LCK 경기 결과·순위·밴픽·메타·팀 지표 분석 |
| transit | `ev-charger-nearby` | 지역·위치별 전기차 충전소·충전 상태 조회 |
| transit | `highway-traffic-status` | 한국도로공사·국가교통정보센터 공개 API로 고속도로 실시간 소통(구간별 속도/교통량/정체 등급)과 CCTV 스트림 메타데이터를 조회한다. |
| transit | `kakao-map` | Kakao Local (장소 검색·주소-좌표 변환) + Kakao Mobility (자동차 길찾기) 를 k-skill-proxy 경유로 조회한다. |
| transit | `korean-transit-route` | 두 장소 사이 지하철·버스·도보 경로 조회 |
| transit | `seoul-bike` | 서울 따릉이 실시간 대여소의 대여 가능 자전거와 빈 거치대를 좌표 주변 또는 대여소 이름으로 조회한다. |
| transit | `seoul-subway-arrival` | 서울 지하철 실시간 도착 정보 조회 |
| transit | `subway-lost-property` | 역·물품별 지하철 유실물 공식 조회 경로 안내 |
| transport | `cheap-gas-nearby` | 위치를 확인한 뒤 주변 저렴한 주유소 조회 |
| transport | `komsa-ferry-info` | 한국해양교통안전공단 KOMSA MTIS 공식 API로 연안여객선 운항 일정과 선박·항로 정보를 조회한다. |
| travel | `express-bus-booking` | 고속버스 시간표·좌석 조회와 공식 예매 흐름 안내 |
| travel | `flight-ticket-search` | Google Flights 공개 검색 표면을 무료로 조회해 항공권 후보, 예약 검색 링크, 날짜/월/연도별 최저가·평균가 비교를 보수적으로 제공한다. |
| travel | `foresttrip-vacancy` | 자연휴양림 숙소·캠핑 빈자리 조회 |
| travel | `intercity-bus-booking` | 시외버스 시간표·좌석·요금 조회와 공식 예매 흐름 안내 |
| travel | `mofa-travel-safety` | 외교부 0404 국가·지역별 여행경보 Open API를 k-skill-proxy 경유로 조회해 국가별 공식 경보 단계와 원문 정보를 제공한다. |
| travel | `myrealtrip-search` | 마이리얼트립 공식 Streamable HTTP MCP 서버로 항공권, 숙소, 투어/티켓/액티비티를 검색하고 상세·가격·예약 링크를 확인한다. |
| travel | `railway-timetable` | KTX 계열 포함 코레일 시간표 조회. 예매·결제 없음 |
| utility | `donation-place-search` | 지역·분야별 기부처 후보와 확인 경로 안내 |
| utility | `fine-dust-location` | 에어코리아 기반 미세먼지/초미세먼지를 지역명 또는 위치 힌트로 조회한다. |
| utility | `han-river-water-level` | 한강홍수통제소 기반 현재 수위/유량을 관측소명 또는 관측소코드로 조회한다. |
| utility | `household-waste-info` | 지역별 생활쓰레기 배출 요일·시간·장소 조회 |
| utility | `k-schoollunch-menu` | 교육청·학교명으로 학교 급식 식단 조회 |
| utility | `korean-holiday-calendar` | 한국천문연구원 특일 정보 API를 k-skill-proxy 경유로 호출해 공휴일·국경일·기념일·24절기·잡절을 조회한다. |
| utility | `library-book-search` | 도서·도서관 소장 여부 검색 |
| utility | `lotto-results` | 로또 회차·당첨번호·번호 일치 조회 |
| utility | `naming-house` | 생년월일시와 성씨·후보 이름을 바탕으로 사주 오행과 성명학 점수를 참고해 어울리는 한국 이름을 추천한다. |
| utility | `saju-fortune` | 사주팔자 정보를 인터뷰로 확인한 뒤 saju-fortune npm package를 사용해 연애운, 재물운, 직업운, 건강운, 한해 운세, 궁합을 대화형으로 풀이한다. |
| utility | `seoul-density` | 서울 주요 121개 핫스팟 장소의 실시간 혼잡도와 인구 현황을 조회한다. |
| utility | `zipcode-search` | 주소로 우편번호·공식 영문 주소 조회 |
| weather | `korea-weather` | 한국 날씨를 기상청 단기예보 조회서비스와 프록시 경유로 조회해 요약한다. |
| writing | `korean-character-count` | 한국어 글자·줄·바이트 수를 정해진 기준으로 계산 |
| writing | `korean-humanizer` | AI가 쓴 티가 나는 한국어 글을 자연스러운 사람 글로 고친다. |
| writing | `korean-middle-korean` | 입력한 한국어를 중세국어풍으로 변환 |
| writing | `korean-slang-writing` | 유행어 후보를 참고해 한국어 표현 작성 |
| writing | `korean-spell-check` | 한국어 맞춤법 검사와 수정 제안 |

## 관련 문서

- [현재 서버 사용법](./usage-guide.md)
- [설치·실행 근거와 한계](./evidence.md)
- [프로젝트 소개](./README.md)

