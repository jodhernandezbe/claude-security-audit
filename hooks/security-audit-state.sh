#!/usr/bin/env bash
# Tracks which source changes have been audited.
#
#   security-audit-state.sh digest   prints a digest of the current unstaged+staged source diff
#   security-audit-state.sh save     records the current digest as audited
#   security-audit-state.sh check    exits 0 when the current diff is already audited, 1 otherwise
#
# The state file lives in .claude/.security-audit-state and is per working tree, not committed.
set -u

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
STATE="$ROOT/.claude/.security-audit-state"
# Paths never worth auditing: docs, planning artifacts, lock files, images.
SKIP_RE='(^|/)(docs|openspec|\.openspec|node_modules|\.venv|dist|build)/|\.(md|txt|lock|png|jpe?g|svg|gif|ico|snap)$|(^|/)__screenshots__/'

digest() {
  git -C "$ROOT" diff HEAD --name-only 2>/dev/null |
    grep -Ev "$SKIP_RE" |
    while IFS= read -r file; do
      printf '%s\n' "$file"
      git -C "$ROOT" diff HEAD -- "$file" 2>/dev/null
    done | shasum | cut -d' ' -f1
}

case "${1:-digest}" in
  digest) digest ;;
  save)
    mkdir -p "$(dirname "$STATE")"
    digest > "$STATE"
    echo "security audit recorded for the current changes"
    ;;
  check)
    now="$(digest)"
    # An empty source diff is nothing to audit.
    [ "$now" = "$(printf '' | shasum | cut -d' ' -f1)" ] && exit 0
    [ -f "$STATE" ] && [ "$now" = "$(cat "$STATE")" ] && exit 0
    exit 1
    ;;
  *)
    echo "usage: $0 [digest|save|check]" >&2
    exit 2
    ;;
esac
