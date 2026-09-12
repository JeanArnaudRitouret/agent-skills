#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
MANIFEST="$REPO_ROOT/skills.manifest"
SOURCE_ROOT="$REPO_ROOT/skills"
PRE_CUTOVER=0

case "${1:-}" in
  "") ;;
  --pre-cutover) PRE_CUTOVER=1 ;;
  *) printf '%s\n' "usage: $0 [--pre-cutover]" >&2; exit 2 ;;
esac

fail() { printf '%s\n' "VERIFY FAIL: $*" >&2; exit 1; }
[ -f "$MANIFEST" ] || fail "missing manifest"

valid_frontmatter() {
  awk 'NR==1 {if ($0 != "---") exit 1} /^name:[[:space:]]*[^[:space:]]/ {name=1} /^description:/ {description=1} /^---$/ && NR>1 {exit !(name && description)} END {if (NR==0) exit 1}' "$1"
}

check_link() {
  skill_name=$1
  host_root=$2
  source="$SOURCE_ROOT/$skill_name"
  target="$host_root/$skill_name"
  [ -f "$source/SKILL.md" ] || fail "missing canonical skill: $skill_name"
  valid_frontmatter "$source/SKILL.md" || fail "invalid frontmatter: $skill_name"
  [ -L "$target" ] || fail "missing link: $target"
  source_real=$(CDPATH= cd -- "$source" && pwd -P)
  target_real=$(CDPATH= cd -- "$target" && pwd -P) || fail "broken link: $target"
  [ "$target_real" = "$source_real" ] || fail "foreign link: $target"
}

while IFS= read -r skill_name || [ -n "$skill_name" ]; do
  [ -n "$skill_name" ] || continue
  check_link "$skill_name" /Users/jeanarnaudritouret/.claude/skills
  check_link "$skill_name" /Users/jeanarnaudritouret/.agents/skills
done < "$MANIFEST"

find /Users/jeanarnaudritouret/.codex/skills -mindepth 1 -maxdepth 1 -type d -print | while IFS= read -r legacy_dir; do
  legacy_name=$(basename -- "$legacy_dir")
  [ "$legacy_name" = .system ] && continue
  if [ "$PRE_CUTOVER" -eq 1 ]; then
    case "$legacy_name" in
      audit-plan-zero-context|explain-like-im-dumb|memory-architecture-docs|test-driven-development) continue ;;
      *) fail "unexpected legacy skill: $legacy_name" ;;
    esac
  fi
  fail "legacy custom skill remains: $legacy_name"
done

printf '%s\n' "VERIFIED shared skill links"
