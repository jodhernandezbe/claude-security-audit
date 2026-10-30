# claude-security-audit

Makes every change in a project get an **independent** security audit, automatically, inside
Claude Code. The agent that wrote the code never reviews its own work.

## The four pieces

| Piece | File | What it does |
| --- | --- | --- |
| Auditor subagent | `.claude/agents/security-auditor.md` | Read-only, separate context. Audits a diff for exploitable defects, verifies each candidate before reporting, cites `file:line` for the input, the sink and the missing check. |
| Command | `.claude/commands/security-audit.md` | `/security-audit`: runs the project's deterministic scanners, then dispatches the auditor, then reports both layers together. |
| Gate hook | `.claude/hooks/security-audit-gate.sh` | A `Stop` hook. When a turn ends with source changes that have not been audited, it tells Claude to run the audit before finishing. |
| State script | `.claude/hooks/security-audit-state.sh` | Digests the current source diff so the gate knows what has already been audited. Not committed. |

Plus two project files you own: `security-audit-scanners.md` (the exact scanner commands) and
`security-audit-rules.md` (findings this project has decided are noise, with reasons).

## Why two layers

Scanners and a model fail differently. Deterministic tools exhaustively check what they know:
secrets, known advisories, taint patterns they ship rules for. They cannot read intent, so they
miss a missing authorisation check or a trust boundary crossed in a way no rule describes. A
model reads intent but is not exhaustive and will invent findings if you let it. Running both,
and making the model verify before reporting, is what keeps the output short enough to read.

## Why independent

A model asked to review its own diff rates its own work. The auditor is a subagent with its own
context: it sees the diff, the repository and the project's exclusions, and nothing of the
reasoning that produced the change. The command is explicit that no hypothesis travels with the
dispatch, because a reviewer handed a conclusion returns it confirmed.

## The one command

Once per machine, link the user-level init command:

```sh
ln -sf ~/Documents/claude-security-audit/user-command/security-audit-init.md ~/.claude/commands/security-audit-init.md
```

It is a symlink, so editing the kit updates the command everywhere. A new command appears in the
next Claude Code session.

Then, in any project:

```
/security-audit-init
```

It runs the installer, works out which scanners that project already has and writes their exact
commands down, asks about the gaps, checks the gate, and lists the files to commit.

## Install by hand

```sh
./install.sh /path/to/project
```

Then fill `.claude/security-audit-scanners.md` with the project's real commands, run
`/security-audit` once, and commit `.claude/`. **Start a new Claude Code session before the
first audit**: subagents in `.claude/agents/` are discovered at session start, so the auditor is
not dispatchable in the session that installed it. Colleagues get everything on their next pull;
Claude Code asks each of them once to trust the project's hooks.

In Claude Code, `/security-audit-init` does all of that for you.

## How the gate behaves

- It fires when the turn ends, not on every edit, so one audit covers a whole piece of work.
- It ignores documentation, planning files, lock files and images.
- It stays silent when the diff it would audit is already recorded as audited.
- It never loops: when Claude is already continuing because of a stop hook, it does nothing.
- It blocks the turn with a reason rather than running anything itself, so no scan ever delays
  your prompt.

To audit a branch or a range instead of the working tree: `/security-audit branch` or
`/security-audit main..HEAD`.

## Writing the scanner commands

Two things make a scanner row wrong in a way that reads as success:

- **A tool that reports "Skipped" or "no files to check" has not passed.** The audit is told to
  report that as a failure to investigate.
- **Shell differences in the file list.** `--files $FILES` word-splits in bash and does not in
  zsh, where the whole list arrives as one argument. Prefer piping the paths into `xargs`, which
  behaves the same in both.

## Tuning the noise

When an audit reports something the team judges not a defect here, add one narrow line to
`.claude/security-audit-rules.md` saying what and why. The auditor reads it on every run. Keep
the rules specific: a broad rule hides real defects, which is the one failure mode worse than
noise.

## Limits

- The auditor reads code; it does not run it. A defect that only appears at runtime is out of
  reach, and it says so rather than guessing.
- It is not hardened against a repository that contains instructions aimed at it. Its prompt
  treats repository text as data, but do not point it at code you do not trust.
- It audits the diff, not the whole codebase. For a full sweep use a dedicated scan.
