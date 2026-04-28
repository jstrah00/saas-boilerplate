# Audits — archive

Historical archive of audits committed before the 2026-04-28 audits/plans/adr refactor. **Read-only history.** Files here are not updated; they describe the state of the repo at the date in their filename.

## Where to write new audits now

Audits about the **Claude setup itself** (alignment between docs and code, drift checks, file cleanup) are ephemeral churn — they go to `.claude/scratch/audits/` (gitignored). Use `/audit-claude-setup` to generate them.

Audits about a **subsystem of the application** (a real architectural concern, e.g. "review the auth flow", "audit the migration story") that are worth preserving as history — keep using this directory with the existing `<topic>-audit-YYYY-MM-DD.md` convention, and pair them with a plan in `../plans/active/`.

## Index (frozen)

- `claude-setup-audit-2026-04-25.md` — full audit of stack, AI config, and code patterns. 3 🔴 CRITICAL gaps + 8 🟡 HIGH. Closed by `../plans/claude-setup-alignment.md`.
- `claude-setup-audit-2026-04-25-followup.md` — same-day follow-up after first remediation pass.
- `claude-setup-audit-2026-04-28.md` — third pass: surfaced 3 new CRITICAL drifts (alembic env.py missing import, init_postgres rule stale, backend/CLAUDE.md endpoint snippet stale) + 1 HIGH (scan-secrets missing Anthropic/OpenAI keys). All closed by commits on `chore/claude-alignment-2026-04-25`.
- `claude-cleanup-audit-2026-04-28.md` — redundancy/legacy/orphan sweep. Closed by `../plans/claude-cleanup.md`.
