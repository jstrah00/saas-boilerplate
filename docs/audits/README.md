# Audits

Point-in-time, read-only assessments of the repo. Each audit captures the state of the codebase, AI configuration, or a specific subsystem at a fixed date and ranks findings by severity (🔴 critical, 🟡 high, 🟢 medium).

## Conventions

- One file per audit, named `<topic>-audit-YYYY-MM-DD.md`.
- Audits never get edited after they're committed — they describe the past. To follow up, write a new audit or a plan in `../plans/`.
- The latest audit is the source of truth for severity-ranked findings; older ones are historical context.

## Index

- `claude-setup-audit-2026-04-25.md` — full audit of stack, AI config, and code patterns. Identified 3 🔴 CRITICAL gaps (multi-tenancy not implemented, SECRET_KEY default trampa, root CLAUDE.md outdated) and 8 🟡 HIGH gaps. Plan that closed most of them: `../plans/claude-setup-alignment.md`.
