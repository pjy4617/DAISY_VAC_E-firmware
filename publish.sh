#!/usr/bin/env bash
#
# DAISY_VAC_E 빌드 산출물(FRONT/BACK × elf/bin/hex)을 이 저장소의 GitHub Release로 게시한다.
# 게시가 끝나면 GitHub Actions가 README.md의 릴리스 노트 구간을 자동으로 갱신한다.
#
#   ./publish.sh v1.0.0
#   ./publish.sh v1.0.1 --notes "ADC 이동평균 윈도우 16 → 32 확대"
#   ./publish.sh v1.1.0 --changelog          # 비공개 소스 커밋 로그 포함(공개 주의)
#   ./publish.sh v1.0.0 --dry-run            # 게시 없이 노트 미리보기
#   ./publish.sh v1.0.0 --update --notes "…" # 이미 게시된 릴리스의 노트만 다시 작성
#
set -euo pipefail

REPO="${FW_REPO:-pjy4617/DAISY_VAC_E-firmware}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${FW_SRC:-$ROOT/../DAISY_VAC_E}"
FRONT_DIR=""
BACK_DIR=""
NOTES=""
INCLUDE_CHANGELOG=0
PRERELEASE=0
UPDATE=0
DRY_RUN=0
TAG=""

die() { echo "오류: $*" >&2; exit 1; }
warn() { echo "경고: $*" >&2; }

usage() {
  sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

옵션:
  --src DIR          소스 저장소 경로 (기본: ../DAISY_VAC_E)
  --front-dir DIR    FRONT 산출물 디렉토리 (기본: <src>/build/Debug-Front)
  --back-dir DIR     BACK  산출물 디렉토리 (기본: <src>/build/Debug-Back)
  --notes TEXT       변경 요약 (릴리스 노트 맨 위에 삽입)
  --notes-file FILE  변경 요약을 파일에서 읽기
  --changelog        비공개 소스 저장소의 커밋 메시지를 노트에 포함 (기본: 비포함)
  --prerelease       프리릴리스로 게시
  --update           이미 게시된 릴리스의 노트를 다시 작성 (첨부 파일은 그대로 유지)
  --dry-run          실제 게시 없이 생성될 노트만 출력
  -h, --help         이 도움말
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)    usage; exit 0 ;;
    --src)        SRC="$2"; shift 2 ;;
    --front-dir)  FRONT_DIR="$2"; shift 2 ;;
    --back-dir)   BACK_DIR="$2"; shift 2 ;;
    --notes)      NOTES="$2"; shift 2 ;;
    --notes-file) [ -f "$2" ] || die "노트 파일을 찾을 수 없습니다: $2"; NOTES="$(cat "$2")"; shift 2 ;;
    --changelog)  INCLUDE_CHANGELOG=1; shift ;;
    --prerelease) PRERELEASE=1; shift ;;
    --update)     UPDATE=1; shift ;;
    --dry-run)    DRY_RUN=1; shift ;;
    -*)           die "알 수 없는 옵션: $1" ;;
    *)            [ -z "$TAG" ] || die "태그는 하나만 지정할 수 있습니다."; TAG="$1"; shift ;;
  esac
done

[ -n "$TAG" ] || { usage; exit 1; }
[[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.]+)?$ ]] \
  || die "태그 형식이 올바르지 않습니다: '$TAG' (예: v1.0.0, v1.0.0-rc1)"

command -v gh >/dev/null || die "gh CLI가 필요합니다."
gh auth status >/dev/null 2>&1 || die "gh 인증이 필요합니다. 'gh auth login'을 먼저 실행하세요."

SRC="$(cd "$SRC" 2>/dev/null && pwd)" || die "소스 저장소를 찾을 수 없습니다: $SRC"
[ -d "$SRC/.git" ] || die "git 저장소가 아닙니다: $SRC"
FRONT_DIR="${FRONT_DIR:-$SRC/build/Debug-Front}"
BACK_DIR="${BACK_DIR:-$SRC/build/Debug-Back}"

# ---- 산출물 확인 ----------------------------------------------------------
ARTIFACTS=()
for ext in elf bin hex; do
  ARTIFACTS+=("$FRONT_DIR/DAISY_VAC_E_Front.$ext")
  ARTIFACTS+=("$BACK_DIR/DAISY_VAC_E_Back.$ext")
done
for f in "${ARTIFACTS[@]}"; do
  [ -f "$f" ] || die "산출물이 없습니다: $f (해당 프리셋으로 먼저 빌드하세요)"
  [ -s "$f" ] || die "산출물이 비어 있습니다: $f"
done

# ---- 소스 메타데이터 ------------------------------------------------------
SRC_COMMIT="$(git -C "$SRC" rev-parse --short HEAD)"
SRC_COMMIT_FULL="$(git -C "$SRC" rev-parse HEAD)"
SRC_BRANCH="$(git -C "$SRC" rev-parse --abbrev-ref HEAD)"
SRC_COMMIT_EPOCH="$(git -C "$SRC" log -1 --format=%ct)"
if [ -n "$(git -C "$SRC" status --porcelain)" ]; then
  warn "소스 저장소에 커밋되지 않은 변경이 있습니다. 릴리스에 'dirty'로 표기합니다."
  SRC_COMMIT="$SRC_COMMIT (dirty)"
fi

# 산출물이 최신 소스 커밋보다 오래되었으면 경고 (빌드 누락 방지)
OLDEST_ARTIFACT_EPOCH="$(stat -c %Y "${ARTIFACTS[@]}" | sort -n | head -1)"
if [ "$OLDEST_ARTIFACT_EPOCH" -lt "$SRC_COMMIT_EPOCH" ]; then
  warn "산출물이 최신 소스 커밋($SRC_COMMIT)보다 오래되었습니다. 재빌드가 필요할 수 있습니다."
fi

BUILD_DATE="$(date -d "@$OLDEST_ARTIFACT_EPOCH" '+%Y-%m-%d %H:%M:%S %Z')"
TOOLCHAIN="$(strings "$FRONT_DIR/DAISY_VAC_E_Front.elf" 2>/dev/null | grep -m1 '^GCC: (' || true)"
[ -n "$TOOLCHAIN" ] || TOOLCHAIN="$(arm-none-eabi-gcc --version 2>/dev/null | head -1 || echo '알 수 없음')"

# ---- 릴리스 노트 생성 -----------------------------------------------------
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
NOTES_FILE="$work/notes.md"

{
  if [ -n "$NOTES" ]; then
    echo "### 변경 사항"
    echo
    printf '%s\n' "$NOTES"
    echo
  fi

  echo "### 빌드 정보"
  echo
  echo "| 항목 | 값 |"
  echo "|---|---|"
  echo "| 소스 커밋 | \`$SRC_COMMIT\` (\`$SRC_BRANCH\`) |"
  echo "| 빌드 프리셋 | \`$(basename "$FRONT_DIR")\` (FRONT) / \`$(basename "$BACK_DIR")\` (BACK) |"
  echo "| 빌드 시각 | $BUILD_DATE |"
  echo "| 타깃 MCU | STM32F405RGT6 |"
  echo "| EtherCAT ESC | LAN9252 |"
  echo "| 툴체인 | $TOOLCHAIN |"
  echo

  echo "### 산출물 (SHA-256)"
  echo
  echo "| 파일 | 크기 | SHA-256 |"
  echo "|---|---:|---|"
  for f in "${ARTIFACTS[@]}"; do
    printf '| `%s` | %s | `%s` |\n' \
      "$(basename "$f")" \
      "$(numfmt --to=iec --format='%.1f' "$(stat -c %s "$f")")" \
      "$(sha256sum "$f" | cut -d' ' -f1)"
  done
  echo

  if [ "$INCLUDE_CHANGELOG" -eq 1 ]; then
    PREV_TAG="$(gh release list --repo "$REPO" --limit 1 --json tagName --jq '.[0].tagName // ""' 2>/dev/null || echo "")"
    echo "### 커밋 로그"
    echo
    if [ -n "$PREV_TAG" ] && git -C "$SRC" rev-parse -q --verify "refs/tags/$PREV_TAG" >/dev/null; then
      git -C "$SRC" log --no-merges --format='- %s (`%h`)' "$PREV_TAG..HEAD"
    else
      echo "_직전 릴리스 태그를 소스 저장소에서 찾지 못해 최근 20개 커밋을 표시합니다._"
      echo
      git -C "$SRC" log --no-merges --format='- %s (`%h`)' -20
    fi
    echo
  fi

  echo "### 플래시"
  echo
  echo '```bash'
  echo "# BACK 보드"
  echo "STM32_Programmer_CLI --connect port=swd --download DAISY_VAC_E_Back.hex -hardRst -rst --start"
  echo "# FRONT 보드"
  echo "STM32_Programmer_CLI --connect port=swd --download DAISY_VAC_E_Front.hex -hardRst -rst --start"
  echo '```'
  echo
  echo "> FRONT/BACK 바이너리는 I/O 매핑이 다릅니다. 보드에 맞는 파일을 사용하세요."
} > "$NOTES_FILE"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "===== [dry-run] $TAG 릴리스 노트 미리보기 ====="
  cat "$NOTES_FILE"
  echo "===== 업로드 예정 파일 ====="
  printf '%s\n' "${ARTIFACTS[@]}"
  exit 0
fi

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  [ "$UPDATE" -eq 1 ] || die "태그 '$TAG' 릴리스가 이미 존재합니다. 노트만 다시 쓰려면 --update, 완전히 새로 올리려면 'gh release delete $TAG --repo $REPO'를 먼저 실행하세요."

  # --update는 첨부 파일을 다시 올리지 않는다. 로컬 산출물이 게시본과 같은지 해시로 대조한다.
  gh release view "$TAG" --repo "$REPO" --json body --jq '.body // ""' > "$work/old.md"
  for f in "${ARTIFACTS[@]}"; do
    if ! grep -qF "$(sha256sum "$f" | cut -d' ' -f1)" "$work/old.md"; then
      warn "로컬 '$(basename "$f")'의 해시가 기존 릴리스 노트에 없습니다."
      warn "산출물이 바뀌었다면 --update 대신 새 버전으로 게시하세요 (파일은 다시 업로드되지 않습니다)."
      break
    fi
  done

  echo "릴리스 '$TAG'의 노트를 다시 작성합니다... (첨부 파일 6개는 그대로 유지)"
  gh release edit "$TAG" --repo "$REPO" --notes-file "$NOTES_FILE" >/dev/null
  echo
  echo "완료: https://github.com/$REPO/releases/tag/$TAG"
  echo "README.md는 GitHub Actions가 자동 갱신합니다 (수동 실행: ./gen-readme.sh)."
  exit 0
elif [ "$UPDATE" -eq 1 ]; then
  die "태그 '$TAG' 릴리스가 없습니다. --update 없이 실행해 새로 게시하세요."
fi

GH_ARGS=(release create "$TAG"
  --repo "$REPO"
  --title "$TAG — DAISY_VAC_E Firmware"
  --notes-file "$NOTES_FILE"
  --target "$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)")
[ "$PRERELEASE" -eq 1 ] && GH_ARGS+=(--prerelease)

echo "릴리스 '$TAG' 게시 중... (파일 ${#ARTIFACTS[@]}개)"
gh "${GH_ARGS[@]}" "${ARTIFACTS[@]}"

echo
echo "완료: https://github.com/$REPO/releases/tag/$TAG"
echo "소스 커밋: $SRC_COMMIT_FULL"
echo "README.md는 GitHub Actions가 자동 갱신합니다 (수동 실행: ./gen-readme.sh)."
