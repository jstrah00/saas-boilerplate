---
description: Run full verification (lint+typecheck+test) on backend and frontend, then open a draft PR
allowed-tools: Bash(uv run:*), Bash(npm run:*), Bash(npm test:*), Bash(gh pr:*), Bash(git push:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*)
---

Verify and ship the current branch.

**Step 1 — figure out what changed**:

!`git diff --name-only master...HEAD`

**Step 2 — backend verification** (only if any backend/ files changed in step 1):

!`cd backend && uv run ruff check app tests`
!`cd backend && uv run mypy app`
!`cd backend && uv run pytest`

**Step 3 — frontend verification** (only if any frontend/ files changed in step 1):

!`cd frontend && npm run lint`
!`cd frontend && npm run build`
!`cd frontend && npm test -- --run`

**Step 4** — if any step above failed, STOP and report the failure verbatim. Do not push.

**Step 5** — if all green, push and open a draft PR:

!`git push -u origin HEAD`
!`gh pr create --draft --fill`

Report the PR URL.
