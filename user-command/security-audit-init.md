---
description: Incorporate the independent security audit workflow into the current project (auditor subagent, /security-audit, Stop gate, scanner config), committed so every colleague gets it by cloning
---

Incorporate the security-audit kit from `~/Documents/claude-security-audit` into the project in
the current working directory. Everything lands inside the project and is meant to be committed,
so colleagues need to install nothing. Work through these steps in order.

1. **Run the installer**: `~/Documents/claude-security-audit/install.sh "$PWD"`. It copies the
   auditor subagent, the `/security-audit` command and the two hook scripts into `.claude/`,
   registers the Stop hook without removing existing hooks, scaffolds the scanner and exclusion
   files only if absent, and adds the state file to `.gitignore`. Report what it printed.

2. **Discover this project's scanners.** Read the project's dependency manifests, pre-commit
   configuration, CI workflows and `CLAUDE.md` to find what already exists for: secret scanning,
   static analysis or security linting, and dependency advisories. Prefer a tool the project
   already runs over installing anything. Check each command actually runs before writing it
   down. Fill `.claude/security-audit-scanners.md` with the exact commands, what a non-zero exit
   means for each, and an honest list of the layers this project does not have.

3. **Ask about the gaps.** If a layer is missing, name it and the cheapest way to add it, and ask
   the user whether to add it now or record it as a known gap. Do not install a tool without
   being asked.

4. **Prove the path works.** Run `/security-audit` on the current changes (or, if the tree is
   clean, on the last commit with `/security-audit HEAD~1..HEAD`). Show the scanner table and the
   auditor's report.

5. **Check the gate.** Verify the Stop hook with a sample payload: feed
   `{"hook_event_name":"Stop","stop_hook_active":false}` to
   `.claude/hooks/security-audit-gate.sh` with unaudited source changes present and confirm it
   asks for an audit, then with `stop_hook_active` true and confirm it stays silent.

6. **Hand over.** List the files to commit (`.claude/agents/security-auditor.md`,
   `.claude/commands/security-audit.md`, `.claude/hooks/security-audit-*.sh`,
   `.claude/settings.json`, the two config files, the `.gitignore` line). Do not commit unless
   the user asks. Mention that the gate will ask for an audit at the end of any turn that
   changes source, and that `/security-audit` can be run at any time.
