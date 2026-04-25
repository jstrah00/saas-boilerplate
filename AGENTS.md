# AGENTS.md

This repository's primary AI configuration is for **Claude Code**. The same Markdown files apply to other agents (Cursor, Aider, Codex CLI, Continue, etc.) — they are written in plain Markdown with stack-specific guidance.

## Where to look

- `CLAUDE.md` (root) — orchestration context, monorepo layout, integration patterns, gotchas.
- `backend/CLAUDE.md` — FastAPI + SQLAlchemy + Alembic conventions, 7-step feature workflow, RBAC.
- `frontend/CLAUDE.md` — React + Vite + TanStack Query + Zustand patterns, feature-based architecture.
- `.claude/rules/` — path-scoped rules referenced from `CLAUDE.md`:
  - `backend-data-layer.md` — repository/service pattern, multi-tenancy gap.
  - `backend-migrations.md` — Alembic autogenerate workflow.
  - `frontend-api.md` — generated types, apiClient, httpOnly cookies.
- `.claude/agents/` — Claude Code subagent definitions (frontmatter + prompt). The prompts are stack-aware and adaptable to other agent runtimes.
- `.claude/skills/`, `backend/.claude/skills/`, `frontend/.claude/skills/` — Claude Code skills covering common scaffolding flows.
- `docs/` — architecture, full-stack workflow, troubleshooting, audits, plans.
