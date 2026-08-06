#!/usr/bin/env bash
#
# README.md의 릴리스 노트 구간(<!-- RELEASES:START --> ~ <!-- RELEASES:END -->)을
# GitHub Releases 정보로 재생성한다.
#
#   ./gen-readme.sh
#
# GitHub Actions(update-readme.yml)가 릴리스 게시/수정/삭제 시 자동 실행하며,
# 로컬에서 수동으로 실행해도 동일한 결과를 만든다.
#
set -euo pipefail

REPO="${FW_REPO:-pjy4617/DAISY_VAC_E-firmware}"
LIMIT="${FW_README_LIMIT:-30}"          # README에 나열할 최대 릴리스 수
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
README="$ROOT/README.md"
START_MARK="<!-- RELEASES:START -->"
END_MARK="<!-- RELEASES:END -->"
BASE="https://github.com/$REPO"

for cmd in gh jq awk; do
  command -v "$cmd" >/dev/null || { echo "오류: '$cmd' 명령이 필요합니다." >&2; exit 1; }
done
[ -f "$README" ] || { echo "오류: README.md를 찾을 수 없습니다: $README" >&2; exit 1; }
grep -qF "$START_MARK" "$README" || { echo "오류: README.md에 $START_MARK 마커가 없습니다." >&2; exit 1; }
grep -qF "$END_MARK"   "$README" || { echo "오류: README.md에 $END_MARK 마커가 없습니다." >&2; exit 1; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# 초안(draft)을 제외한 릴리스 목록을 최신순으로 수집
gh release list --repo "$REPO" --limit "$LIMIT" \
    --json tagName,name,publishedAt,isDraft,isPrerelease \
  | jq 'map(select(.isDraft | not))' > "$work/releases.json"

count="$(jq 'length' "$work/releases.json")"
echo "릴리스 ${count}건을 README에 반영합니다."

{
  echo "$START_MARK"
  echo
  echo "## 릴리스 노트"
  echo

  if [ "$count" -eq 0 ]; then
    echo "_아직 게시된 릴리스가 없습니다._"
  else
    echo "| 버전 | 게시일 | FRONT | BACK |"
    echo "|---|---|---|---|"
    jq -r --arg base "$BASE" '
      .[] |
      . as $r |
      ["hex","bin","elf"] as $ext |
      "| [\($r.tagName)](\($base)/releases/tag/\($r.tagName))"
        + (if $r.isPrerelease then " `pre`" else "" end)
      + " | \($r.publishedAt[0:10])"
      + " | " + ([ $ext[] | "[\(.)](\($base)/releases/download/\($r.tagName)/DAISY_VAC_E_Front.\(.))" ] | join(" · "))
      + " | " + ([ $ext[] | "[\(.)](\($base)/releases/download/\($r.tagName)/DAISY_VAC_E_Back.\(.))"  ] | join(" · "))
      + " |"
    ' "$work/releases.json"
    echo

    while IFS= read -r tag; do
      [ -n "$tag" ] || continue
      body="$(gh release view "$tag" --repo "$REPO" --json body --jq '.body // ""' | tr -d '\r')"
      echo "<details>"
      echo "<summary><b>$tag</b> 상세 노트</summary>"
      echo
      if [ -n "${body//[[:space:]]/}" ]; then
        printf '%s\n' "$body"
      else
        echo "_릴리스 노트가 비어 있습니다._"
      fi
      echo
      echo "</details>"
      echo
    done < <(jq -r '.[].tagName' "$work/releases.json")
  fi

  echo "$END_MARK"
} > "$work/block.md"

# 기존 마커 구간을 새 블록으로 치환
awk -v start="$START_MARK" -v end="$END_MARK" -v repl="$work/block.md" '
  index($0, start) { skip = 1; while ((getline line < repl) > 0) print line; close(repl); next }
  index($0, end)   { skip = 0; next }
  !skip            { print }
' "$README" > "$work/README.md"

if cmp -s "$work/README.md" "$README"; then
  echo "README.md 변경 없음."
else
  mv "$work/README.md" "$README"
  echo "README.md를 갱신했습니다."
fi
