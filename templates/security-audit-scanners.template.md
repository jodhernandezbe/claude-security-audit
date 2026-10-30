# Deterministic security scanners

Read by `/security-audit` before the independent auditor runs. One row per layer. Keep the
commands exact and runnable from the repository root. Mark a layer "not configured" rather than
inventing a command; the audit reports it as such.

| Layer | Command | Notes |
| --- | --- | --- |
| Secrets | | Scans the diff for credentials |
| Static analysis / security lint | | Over the changed source only, where the tool supports it |
| Dependency advisories | | Only when a manifest or lock file changed |

## Exit codes

Say what a non-zero exit means for each command, so a failure is reported accurately rather than
treated as a finding or swallowed.

## Not configured

List the layers this project does not have and why, so the gap is visible instead of silent.
