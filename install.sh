#!/usr/bin/env bash
# Install (or refresh) the security-audit kit in a project.
#
#   ./install.sh <project-root>
#
# Copies the auditor subagent, the /security-audit command and the two hook scripts into
# <project>/.claude/, adds the Stop hook to <project>/.claude/settings.json without removing
# existing hooks, and scaffolds the scanners and exclusions files only when absent.
# Safe to run repeatedly. Everything it writes belongs in the repository.
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${1:-}"

if [ -z "$PROJECT" ] || [ ! -d "$PROJECT" ]; then
  echo "usage: $0 <project-root>" >&2
  exit 1
fi
PROJECT="$(cd "$PROJECT" && pwd)"
say() { printf '  %s\n' "$*"; }

echo "security-audit -> $PROJECT"

mkdir -p "$PROJECT/.claude/agents" "$PROJECT/.claude/commands" "$PROJECT/.claude/hooks"
cp "$KIT/agents/security-auditor.md" "$PROJECT/.claude/agents/security-auditor.md"
cp "$KIT/commands/security-audit.md" "$PROJECT/.claude/commands/security-audit.md"
cp "$KIT/hooks/security-audit-gate.sh" "$PROJECT/.claude/hooks/security-audit-gate.sh"
cp "$KIT/hooks/security-audit-state.sh" "$PROJECT/.claude/hooks/security-audit-state.sh"
chmod +x "$PROJECT/.claude/hooks/security-audit-gate.sh" "$PROJECT/.claude/hooks/security-audit-state.sh"
say "agent    .claude/agents/security-auditor.md"
say "command  .claude/commands/security-audit.md"
say "hooks    .claude/hooks/security-audit-{gate,state}.sh"

SETTINGS="$PROJECT/.claude/settings.json"
SNIPPET="$(cat "$KIT/hooks/settings.hooks.json")"
if ! command -v jq >/dev/null 2>&1; then
  say "settings jq not found: add this Stop hook to $SETTINGS by hand:"
  printf '%s\n' "$SNIPPET"
elif [ ! -f "$SETTINGS" ]; then
  printf '%s\n' "$SNIPPET" > "$SETTINGS"
  say "settings .claude/settings.json created with the Stop hook"
elif jq -e '[.hooks.Stop[]?.hooks[]?.command // "" | select(contains("security-audit-gate.sh"))] | length > 0' "$SETTINGS" >/dev/null; then
  say "settings Stop hook already registered (unchanged)"
else
  ENTRY="$(printf '%s' "$SNIPPET" | jq '.hooks.Stop[0]')"
  TMP="$(mktemp)"
  jq --argjson entry "$ENTRY" '.hooks = (.hooks // {}) | .hooks.Stop = ((.hooks.Stop // []) + [$entry])' "$SETTINGS" > "$TMP"
  mv "$TMP" "$SETTINGS"
  say "settings Stop hook appended to existing .claude/settings.json"
fi

for f in security-audit-scanners security-audit-rules; do
  if [ -f "$PROJECT/.claude/$f.md" ]; then
    say "config   .claude/$f.md exists (left untouched)"
  else
    cp "$KIT/templates/$f.template.md" "$PROJECT/.claude/$f.md"
    say "config   .claude/$f.md scaffolded from the template"
  fi
done

# The state file is per working tree, never committed.
IGNORE="$PROJECT/.gitignore"
if [ -f "$IGNORE" ] && ! grep -q '\.security-audit-state' "$IGNORE"; then
  printf '\n# Which changes the security audit has already seen (per working tree)\n.claude/.security-audit-state\n' >> "$IGNORE"
  say "gitignore .claude/.security-audit-state added"
fi

cat <<EOF

Next steps (or run /security-audit-init in Claude Code, which does them):
  1. Fill .claude/security-audit-scanners.md with this project's real scanner commands.
  2. Run /security-audit once to see the whole path work.
  3. Commit .claude/ so colleagues get the auditor, the command and the gate by cloning.
EOF
