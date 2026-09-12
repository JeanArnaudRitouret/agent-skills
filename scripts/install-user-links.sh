#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
MANIFEST="$REPO_ROOT/skills.manifest"
APPLY=0

case "${1:-}" in
  "") ;;
  --apply) APPLY=1 ;;
  *) printf '%s\n' "usage: $0 [--apply]" >&2; exit 2 ;;
esac

[ -f "$MANIFEST" ] || { printf '%s\n' "missing manifest: $MANIFEST" >&2; exit 1; }

SOURCE_ROOT="$REPO_ROOT/skills"
SOURCE_ROOT_REAL=$(CDPATH= cd -- "$SOURCE_ROOT" && pwd -P)
REPLACEMENT_NEEDED=0
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)

install_target() {
  skill_name=$1
  host_name=$2
  host_root=$3
  source="$SOURCE_ROOT/$skill_name"
  target="$host_root/$skill_name"
  expected=$(CDPATH= cd -- "$source" && pwd -P)

  [ -f "$source/SKILL.md" ] || { printf '%s\n' "missing canonical skill: $source" >&2; exit 1; }

  if [ -L "$target" ]; then
    actual=$(CDPATH= cd -- "$target" && pwd -P) || {
      printf '%s\n' "broken link: $target" >&2; exit 1;
    }
    [ "$actual" = "$expected" ] || {
      printf '%s\n' "refusing foreign link: $target -> $actual" >&2; exit 1;
    }
    printf '%s\n' "UNCHANGED $target"
    return
  fi

  if [ -e "$target" ]; then
    REPLACEMENT_NEEDED=1
    backup="$REPO_ROOT/.migration-backup/$TIMESTAMP/$host_name/$skill_name"
    if [ "$APPLY" -eq 0 ]; then
      printf '%s\n' "MOVE $target -> $backup"
      printf '%s\n' "LINK $target -> $source"
      return
    fi
    [ ! -e "$backup" ] || { printf '%s\n' "backup collision: $backup" >&2; exit 1; }
    mkdir -p "$(dirname -- "$backup")"
    mv "$target" "$backup"
  else
    printf '%s\n' "LINK $target -> $source"
    [ "$APPLY" -eq 1 ] || return 0
  fi

  mkdir -p "$host_root"
  ln -s "$source" "$target"
}

while IFS= read -r skill_name || [ -n "$skill_name" ]; do
  [ -n "$skill_name" ] || continue
  case "$skill_name" in
    *[!a-z0-9-]* ) printf '%s\n' "invalid manifest skill: $skill_name" >&2; exit 1 ;;
  esac
  install_target "$skill_name" claude /Users/jeanarnaudritouret/.claude/skills
  install_target "$skill_name" agents /Users/jeanarnaudritouret/.agents/skills
done < "$MANIFEST"

[ "$SOURCE_ROOT_REAL" = "$(CDPATH= cd -- "$SOURCE_ROOT" && pwd -P)" ]
if [ "$APPLY" -eq 0 ] && [ "$REPLACEMENT_NEEDED" -eq 1 ]; then
  printf '%s\n' "dry run found replacements; rerun with --apply after review" >&2
  exit 1
fi
