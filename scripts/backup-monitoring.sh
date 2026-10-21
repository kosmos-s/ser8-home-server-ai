#!/usr/bin/env bash
# backup-monitoring.sh — Beszel Hub·Agent, Uptime Kuma 데이터·구성 백업 초안
#
# 상태: 초안. 작성 시점(2026-10-21)에 실행·시험하지 않았다.
#       실제 운영 설정이 아니며, 처음 사용할 때는 --dry-run으로 먼저 확인한다.
#
# 사용법:
#   sudo ./backup-monitoring.sh --dest <backup-destination> [옵션]
#
# 옵션:
#   --dest <dir>          백업을 저장할 기존 디렉터리 (필수)
#   --source-root <dir>   모니터링 Compose 상위 경로 (기본: /opt/homelab/monitoring)
#   --require-mount       저장 위치가 루트(/) 또는 원본과 같은 파일시스템이면 중단
#   --dry-run             사전 조건 확인과 실행 계획만 출력, 컨테이너·파일 변경 없음
#   -h, --help            도움말
#
# 동작 요약:
#   1. 사전 조건 확인 (root, 명령, Compose 파일, 저장 위치, 여유 공간)
#   2. flock으로 중복 실행 방지
#   3. 모든 대상 컨테이너의 상태를 먼저 확인 (오류·이상 상태면 아무것도 멈추지 않고 중단)
#   4. 원래 실행 중이던 Beszel Agent·Hub, Uptime Kuma만 잠시 중지
#   5. 서비스 디렉터리를 tar.gz로 묶은 뒤, 이 스크립트가 중지한 컨테이너만 역순으로 재시작
#   6. 압축 읽기 검사, SHA-256 체크섬·목록 생성 후 완성 디렉터리로 이동
#   오류·신호 발생 시: 중지한 컨테이너 재시작, 이번 실행의 미완성 작업 디렉터리만 삭제
#   재시작 실패: 서비스 이름을 출력하고 종료 코드 1 (백업이 만들어졌더라도 성공으로 보고하지 않음)
#
# 하지 않는 것: 오래된 백업 자동 삭제, 외부 저장장치 복사, Open WebUI 백업.
#
# 주의: 백업본에는 Compose 파일의 Agent 인증값과 Hub 개인 키가 포함된다.
#       저장소·공개 위치에 두지 않는다.

set -Eeuo pipefail
umask 077

readonly LOCK_FILE="/run/lock/backup-monitoring.lock"

# 서비스 정의: "<compose 디렉터리>:<서비스 목록(공백 구분, 중지 순서)>"
# 재시작은 중지의 역순이다 (Hub를 먼저 올린 뒤 Agent).
# Agent 데이터 디렉터리도 실행 중 변경되지 않는다는 근거가 없어 함께 중지한다.
readonly -a PROJECTS=(
  "beszel:beszel-agent beszel"
  "uptime-kuma:uptime-kuma"
)
# 백업에서 제외할 경로 (source-root 기준, 실행 중 생성되는 소켓)
readonly -a EXCLUDES=(
  "beszel/beszel_socket"
)

SOURCE_ROOT="/opt/homelab/monitoring"
DEST=""
REQUIRE_MOUNT=0
DRY_RUN=0

PLAN=()            # "<compose 파일>|<서비스>|<시작 전 상태>"
STOPPED=()         # "<compose 파일>|<서비스>" — 이 스크립트가 중지한 것만 기록
RESTART_FAILED=()  # 재시작하지 못한 서비스 이름
WORK_DIR=""        # 이번 실행이 만든 미완성 작업 디렉터리 (완성 후 비움)

log()  { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
warn() { printf '[%s] 경고: %s\n' "$(date '+%F %T')" "$*" >&2; }
die()  { printf '[%s] 오류: %s\n' "$(date '+%F %T')" "$*" >&2; exit 1; }

usage() { sed -n '2,/^$/{s/^# \{0,1\}//;p}' "$0"; }

parse_args() {
  while (($#)); do
    case "$1" in
      --dest|--source-root) (($# >= 2)) || die "$1 에 값이 필요합니다." ;;&
      --dest)          DEST="$2"; shift 2 ;;
      --source-root)   SOURCE_ROOT="$2"; shift 2 ;;
      --require-mount) REQUIRE_MOUNT=1; shift ;;
      --dry-run)       DRY_RUN=1; shift ;;
      -h|--help)       usage; exit 0 ;;
      *)               die "알 수 없는 인자: $1 (--help 참고)" ;;
    esac
  done
  [[ -n "$DEST" ]] || die "--dest <backup-destination> 가 필요합니다."
  [[ -n "$SOURCE_ROOT" ]] || die "--source-root 값이 비었습니다."
}

project_dirs() {
  local entry
  for entry in "${PROJECTS[@]}"; do printf '%s\n' "${entry%%:*}"; done
}

check_destination_fs() {
  local dest_mount dest_dev src_dev problem=""
  dest_mount="$(findmnt -n -o TARGET -T "$DEST")" || die "저장 위치의 마운트 정보를 확인할 수 없습니다."
  dest_dev="$(stat -c %d -- "$DEST")" || die "저장 위치 정보를 읽을 수 없습니다."
  src_dev="$(stat -c %d -- "$SOURCE_ROOT")" || die "원본 경로 정보를 읽을 수 없습니다."

  # 외부 장치가 마운트되지 않으면 빈 마운트 지점이 루트 파일시스템에 속한다.
  if [[ "$dest_mount" == "/" ]]; then
    problem="루트 파일시스템"
  elif [[ "$dest_dev" == "$src_dev" ]]; then
    problem="백업 원본과 같은 파일시스템"
  fi
  [[ -z "$problem" ]] && return 0

  if ((REQUIRE_MOUNT)); then
    die "저장 위치가 ${problem}에 있습니다 (--require-mount). 외부 저장장치가 마운트됐는지 확인하세요."
  fi
  warn "저장 위치가 ${problem}에 있습니다. 같은 디스크 고장에는 대비되지 않습니다."
}

check_prerequisites() {
  [[ $EUID -eq 0 ]] || die "root 권한이 필요합니다 (데이터 디렉터리와 Docker 소켓 접근)."

  local cmd
  for cmd in docker tar gzip sha256sum flock findmnt stat df du mktemp realpath; do
    command -v "$cmd" >/dev/null 2>&1 || die "필요한 명령이 없습니다: $cmd"
  done
  docker compose version >/dev/null 2>&1 || die "docker compose 플러그인을 사용할 수 없습니다."

  SOURCE_ROOT="$(realpath -e -- "$SOURCE_ROOT")" || die "원본 경로가 없습니다."
  DEST="$(realpath -e -- "$DEST")" || die "저장 위치가 없습니다. 먼저 디렉터리를 만들고 다시 실행하세요."
  [[ -d "$DEST" && -w "$DEST" ]] || die "저장 위치가 쓰기 가능한 디렉터리가 아닙니다: $DEST"

  case "$DEST/" in
    "$SOURCE_ROOT"/*) die "저장 위치가 백업 원본 내부에 있습니다." ;;
  esac

  local dir
  while read -r dir; do
    [[ -f "$SOURCE_ROOT/$dir/compose.yaml" ]] || die "Compose 파일이 없습니다: $SOURCE_ROOT/$dir/compose.yaml"
  done < <(project_dirs)

  check_destination_fs

  # 여유 공간: 원본 크기(압축 전) + 10% 이상
  local need_kb avail_kb
  local -a src_dirs
  mapfile -t src_dirs < <(project_dirs)
  need_kb=$(du -sk "${src_dirs[@]/#/$SOURCE_ROOT/}" | awk '{s+=$1} END {print int(s*1.1)+1024}') \
    || die "원본 크기를 계산할 수 없습니다."
  avail_kb=$(df -Pk "$DEST" | awk 'NR==2 {print $4}') || die "저장 위치 여유 공간을 확인할 수 없습니다."
  ((avail_kb > need_kb)) || die "여유 공간 부족: 필요 약 ${need_kb}KB, 사용 가능 ${avail_kb}KB"
}

service_state() {   # $1=compose 파일, $2=서비스 → 컨테이너 상태 출력 (없으면 빈 문자열)
  docker compose -f "$1" ps -a --format '{{.State}}' "$2"
}

# 아무것도 멈추기 전에 모든 대상의 상태를 확인한다.
# docker 오류, 컨테이너 없음, running/exited/created 이외 상태면 중단한다.
plan_services() {
  local entry dir file svc state
  PLAN=()
  for entry in "${PROJECTS[@]}"; do
    dir="${entry%%:*}"; file="$SOURCE_ROOT/$dir/compose.yaml"
    for svc in ${entry#*:}; do
      state="$(service_state "$file" "$svc")" || die "컨테이너 상태를 확인할 수 없습니다: $svc"
      case "$state" in
        running|exited|created) ;;
        "") die "서비스 컨테이너를 찾지 못했습니다: $svc (Compose 프로젝트 이름 확인 필요)" ;;
        *)  die "백업하기에 안전하지 않은 상태입니다: $svc=$(tr '\n' ' ' <<<"$state")" ;;
      esac
      PLAN+=("$file|$svc|$state")
    done
  done
}

# 중지의 역순으로 재시작하고, 실제 running 상태까지 확인한다.
# 실패한 서비스는 RESTART_FAILED에 남겨 마지막에 실패로 보고한다.
restart_stopped() {
  local i file svc state
  for ((i = ${#STOPPED[@]} - 1; i >= 0; i--)); do
    file="${STOPPED[i]%%|*}"; svc="${STOPPED[i]#*|}"
    log "재시작: $svc"
    if docker compose -f "$file" start "$svc"; then
      state="$(service_state "$file" "$svc" 2>/dev/null || true)"
      if [[ "$state" == "running" ]]; then
        continue
      fi
      warn "재시작 후 상태가 running이 아닙니다: $svc=${state:-unknown}"
    else
      warn "재시작 명령 실패: $svc"
    fi
    warn "수동 확인 필요: docker compose -f $file start $svc"
    RESTART_FAILED+=("$svc")
  done
  STOPPED=()
}

cleanup() {
  local rc=$?
  trap - EXIT
  trap '' INT TERM HUP   # 복구 중에는 신호로 중단되지 않게 한다
  if ((${#STOPPED[@]})); then
    warn "중단 감지: 이 스크립트가 중지한 컨테이너를 재시작합니다."
    restart_stopped
  fi
  # 이번 실행이 mktemp로 만든 디렉터리만 지운다. 완성된 백업과 기존 백업은 건드리지 않는다.
  if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
    rm -rf -- "$WORK_DIR"
    warn "이번 실행의 미완성 백업을 삭제했습니다."
  fi
  if ((${#RESTART_FAILED[@]})); then
    warn "재시작하지 못한 서비스: ${RESTART_FAILED[*]}"
    ((rc)) || rc=1
  fi
  exit "$rc"
}

main() {
  parse_args "$@"
  check_prerequisites

  local ts name
  ts="$(date +%Y%m%d-%H%M%S)"
  name="monitoring-$ts"
  [[ ! -e "$DEST/$name" ]] || die "같은 이름의 백업이 이미 있습니다: $DEST/$name"

  local -a dirs tar_excludes=()
  mapfile -t dirs < <(project_dirs)
  local ex
  for ex in "${EXCLUDES[@]}"; do tar_excludes+=("--exclude=./$ex"); done

  local item file svc state

  if ((DRY_RUN)); then
    plan_services
    log "[dry-run] 원본: $SOURCE_ROOT (${dirs[*]})"
    log "[dry-run] 제외: ${EXCLUDES[*]}"
    log "[dry-run] 저장: $DEST/$name/"
    for item in "${PLAN[@]}"; do
      IFS='|' read -r file svc state <<<"$item"
      if [[ "$state" == "running" ]]; then
        log "[dry-run] 실행 중 → 백업 중 잠시 중지 후 재시작 예정: $svc"
      else
        log "[dry-run] $state → 중지·재시작하지 않음: $svc"
      fi
    done
    log "[dry-run] 변경 없이 종료합니다."
    return 0
  fi

  exec 9>"$LOCK_FILE"
  flock -n 9 || die "다른 백업이 실행 중입니다 ($LOCK_FILE)."

  trap cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  trap 'exit 129' HUP

  plan_services
  WORK_DIR="$(mktemp -d "$DEST/.incomplete-$name.XXXXXX")"

  # 1) 원래 실행 중인 서비스만 중지 (멈춰 있던 서비스는 건드리지 않음)
  #    중지 명령 전에 기록해, 중지 도중 실패해도 재시작 대상에 포함한다.
  for item in "${PLAN[@]}"; do
    IFS='|' read -r file svc state <<<"$item"
    if [[ "$state" == "running" ]]; then
      log "중지: $svc"
      STOPPED+=("$file|$svc")
      docker compose -f "$file" stop "$svc"
    else
      log "실행 중 아님($state), 그대로 둠: $svc"
    fi
  done

  # 2) 압축 (중지 상태에서 SQLite 본 파일과 -wal/-shm을 함께 복사)
  log "압축: ${dirs[*]}"
  tar --numeric-owner "${tar_excludes[@]}" \
      -C "$SOURCE_ROOT" -czf "$WORK_DIR/$name.tar.gz" "${dirs[@]/#/./}"

  # 3) 다운타임을 줄이기 위해 검사 전에 바로 재시작
  #    재시작에 실패해도 이미 만든 백업은 검사·보존하고, 마지막에 실패 코드로 끝낸다.
  restart_stopped

  # 4) 검사·체크섬·목록
  log "압축 읽기 검사"
  gzip -t "$WORK_DIR/$name.tar.gz"
  tar -tzf "$WORK_DIR/$name.tar.gz" > "$WORK_DIR/$name.files.txt"
  (cd "$WORK_DIR" && sha256sum "$name.tar.gz" "$name.files.txt" > SHA256SUMS)
  (cd "$WORK_DIR" && sha256sum -c --quiet SHA256SUMS)

  chmod 0700 "$WORK_DIR"
  chmod 0600 "$WORK_DIR"/*
  # -T: 대상이 이미 있을 때 그 안으로 옮기지 않는다
  mv -T -- "$WORK_DIR" "$DEST/$name"
  WORK_DIR=""
  log "백업 저장: $DEST/$name/"

  if ((${#RESTART_FAILED[@]})); then
    die "백업은 저장했지만 일부 컨테이너 재시작에 실패했습니다."
  fi
  log "완료"
}

main "$@"
