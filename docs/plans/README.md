# Plans

Three roles after the 2026-04-28 audits/plans/adr refactor:

## 1. `active/` — committed, in-flight feature plans

Multi-day feature plans worth tracking in version control while the work is ongoing. Each plan:

- Has a Context section, principles, tiered changes (with explicit approval gates), explicit non-goals, execution order, and a verification checklist.
- One file per plan, named after the work — slug, not date — e.g. `auth-cookie-rotation.md`, `org-tenant-introduction.md`.
- Edited as work progresses (checked-off items, scope changes). Diff history shows the evolution.
- A plan is "done" when every Tier is either executed or explicitly rejected. **On completion, decide:**
  - **Promote** to `../adr/` if the plan shipped an architectural decision worth preserving as history.
  - **Delete** if the plan was tactical implementation work; the commits + PR description are the durable record.
- Cross-link the audit (if any) that motivated the plan at the top.

## 2. Root of `docs/plans/` — archive (read-only)

Historical archive of plans committed before the 2026-04-28 refactor. Files here are not updated; they describe the cleanup/alignment work that ran on `chore/claude-alignment-2026-04-25`.

### Index (frozen)

- `claude-setup-alignment.md` — closes findings from `../audits/claude-setup-audit-2026-04-25.md`. Tier 1/2/3 alignment work.
- `claude-setup-alignment-followup.md` — same-day follow-up plan.
- `claude-setup-alignment-2026-04-28.md` — third pass plan (alembic env.py, scan-secrets, etc.).
- `claude-cleanup.md` — redundancy/legacy cleanup plan; closes `../audits/claude-cleanup-audit-2026-04-28.md`.

## 3. Tactical / ephemeral plans → `.claude/scratch/plans/`

Plans about the Claude setup itself (alignment, drift, cleanup) are gitignored. They live at `.claude/scratch/plans/` and are borrable libre. If any one of them turns into a real architectural decision, promote it to `../adr/`.
