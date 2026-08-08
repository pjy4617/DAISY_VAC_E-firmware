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

# 초안(draft)을 제외한 릴리스 목록을 최신순으로 수집.
#
# `gh release list` 대신 REST API를 쓰는 이유: 자산 이름에 버전이 들어가면서
# (DAISY_VAC_E_Front_v2.0.0.hex) 링크를 이름 규칙으로 조립하는 것이 깨지기 쉬워졌다.
# 조립 방식은 실제로 한 번 사고를 냈다 — v2.0.0 게시 직후 이 스크립트의 옛 버전이
# 버전 없는 이름으로 링크를 만들어 6개가 404였다. 실제 자산 목록의 URL을 그대로 읽으면
# 이름 규칙이 어떻게 바뀌든, 규칙 밖 자산이 섞여 있든 링크가 항상 맞는다.
gh api "repos/$REPO/releases?per_page=$LIMIT" \
  | jq '[ .[]
          | select(.draft | not)
          | { tagName:      .tag_name,
              publishedAt:  .published_at,
              isPrerelease: .prerelease,
              assets:       [ .assets[] | {name, url: .browser_download_url} ] } ]' \
  > "$work/releases.json"

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
    # 보드 한쪽의 셀을 실제 자산에서 만든다. 이름은 `…_Front.hex`(옛 릴리스)와
    # `…_Front_v2.0.0.hex`(버전 삽입 이후) 두 형태를 모두 받는다.
    jq -r --arg base "$BASE" '
      def cell($r; $board):
        ( ["hex","bin","elf"]
          | map( . as $e
                 | ( $r.assets
                     | map(select(.name | test("_\($board)(_[^/]*)?\\.\($e)$"; "i")))
                     | first )
                 | if . == null then empty else "[\($e)](\(.url))" end ) )
        | if length == 0 then "—" else join(" · ") end;
      .[] |
      . as $r |
      "| [\($r.tagName)](\($base)/releases/tag/\($r.tagName))"
        + (if $r.isPrerelease then " `pre`" else "" end)
      + " | \($r.publishedAt[0:10])"
      + " | " + cell($r; "Front")
      + " | " + cell($r; "Back")
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
