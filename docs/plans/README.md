# Plans

Multi-step implementation plans tracked in version control. Each plan has a context section, principles, tiered changes (with explicit approval gates), explicit non-goals, an execution order, and a verification checklist.

## Conventions

- One file per plan, named after the work — slug, not date — e.g. `claude-setup-alignment.md`, `auth-cookie-rotation.md`.
- Plans get edited as work progresses (checked-off items, scope changes). Diff history shows the evolution.
- A plan is "done" when every Tier is either executed or explicitly rejected. Don't delete completed plans — they document why decisions were made.
- Cross-link the audit that motivated the plan (if any) at the top.

## Index

- `claude-setup-alignment.md` — closes findings from `../audits/claude-setup-audit-2026-04-25.md`. Tier 1 (zero-risk additives), Tier 2 (modifications to existing files), Tier 3 (code refactors with regression tests).
