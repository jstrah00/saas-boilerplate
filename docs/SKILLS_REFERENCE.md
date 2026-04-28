# Skills Reference

Human-readable index of every Claude Code skill in this monorepo. One paragraph per skill plus a link to its full `SKILL.md`. Authoritative metadata (descriptions, locations) lives in `.claude/settings.json` — this file is the prose companion.

**Skills**: 3 root + 6 backend + 5 frontend = 14.

---

## Root — cross-stack orchestrators (`.claude/skills/`)

- **`/backend-first`** — Backend-first fullstack workflow: data models → migrations → endpoints → tests → generate types → frontend integration. Recommended default for data-driven features (CRUD, dashboards). Full prompt at [`.claude/skills/backend-first/SKILL.md`](../.claude/skills/backend-first/SKILL.md).
- **`/api-to-ui`** — Build the React UI layer for an API that already exists: types from OpenAPI, axios client, TanStack Query hooks, components, pages. Full prompt at [`.claude/skills/api-to-ui/SKILL.md`](../.claude/skills/api-to-ui/SKILL.md).
- **`/fullstack-feature`** — Greenfield CRUD with explicit planning + DB choice + RBAC. Combines `/backend-first` and `/api-to-ui` in one session. Most comprehensive. Full prompt at [`.claude/skills/fullstack-feature/SKILL.md`](../.claude/skills/fullstack-feature/SKILL.md).

## Backend — FastAPI per-layer (`backend/.claude/skills/`)

- **`/fastapi-endpoint`** — Complete CRUD endpoint: model + schema + repository + service + router with the canonical `CurrentUser` and `*Svc` `Annotated` deps from `app/api/deps.py`. Full prompt at [`backend/.claude/skills/fastapi-endpoint/SKILL.md`](../backend/.claude/skills/fastapi-endpoint/SKILL.md).
- **`/fastapi-model`** — SQLAlchemy 2.0 async model with proper typing, FK relationships, and the project's mapped-column conventions. Full prompt at [`backend/.claude/skills/fastapi-model/SKILL.md`](../backend/.claude/skills/fastapi-model/SKILL.md).
- **`/fastapi-migration`** — Create / manage / troubleshoot Alembic migrations. Enforces the autogenerate-only workflow from `.claude/rules/backend-migrations.md` and reviews generated SQL before applying. Full prompt at [`backend/.claude/skills/fastapi-migration/SKILL.md`](../backend/.claude/skills/fastapi-migration/SKILL.md).
- **`/fastapi-permission`** — Add a `Permission` enum entry, map to roles in `ROLE_PERMISSIONS`, gate endpoints with `@require_permissions(...)`. Full prompt at [`backend/.claude/skills/fastapi-permission/SKILL.md`](../backend/.claude/skills/fastapi-permission/SKILL.md).
- **`/fastapi-test`** — Unit + integration tests with pytest, factory-boy, async httpx client. Reads project conventions from `tests/conftest.py`. Full prompt at [`backend/.claude/skills/fastapi-test/SKILL.md`](../backend/.claude/skills/fastapi-test/SKILL.md).
- **`/feature-from-plan`** — Implement a feature end-to-end from a structured Claude.ai Project plan (markdown spec → code across all layers). Full prompt at [`backend/.claude/skills/feature-from-plan/SKILL.md`](../backend/.claude/skills/feature-from-plan/SKILL.md).

## Frontend — React per-layer (`frontend/.claude/skills/`)

- **`/react-component`** — Feature-specific React component with TypeScript, Tailwind, shadcn/ui patterns. Full prompt at [`frontend/.claude/skills/react-component/SKILL.md`](../frontend/.claude/skills/react-component/SKILL.md).
- **`/react-form`** — Form component with Zod schema + react-hook-form + the project's `<FormField>` wrappers. Generates schema and component together. Full prompt at [`frontend/.claude/skills/react-form/SKILL.md`](../frontend/.claude/skills/react-form/SKILL.md).
- **`/api-integration`** — Two-layer TanStack Query integration: API client functions (`features/<name>/api/`) + React Query hooks (`features/<name>/hooks/`). Full prompt at [`frontend/.claude/skills/api-integration/SKILL.md`](../frontend/.claude/skills/api-integration/SKILL.md).
- **`/react-feature`** — Complete feature folder scaffold: `api/`, `hooks/`, `schemas/`, `components/`, `pages/`. Full prompt at [`frontend/.claude/skills/react-feature/SKILL.md`](../frontend/.claude/skills/react-feature/SKILL.md).
- **`/react-page`** — Page component with route entry and lazy loading. Full prompt at [`frontend/.claude/skills/react-page/SKILL.md`](../frontend/.claude/skills/react-page/SKILL.md).

---

## How to choose

```
Need a feature?
├─ Backend + frontend, nothing exists  →  /fullstack-feature   (or /backend-first if you want more control)
├─ Backend exists, build UI            →  /api-to-ui
└─ Touching only one layer             →  use the per-layer skill
```

| You need | Skill |
|---|---|
| New CRUD resource (data-driven) | `/backend-first` |
| Greenfield with full planning | `/fullstack-feature` or `/feature-from-plan` |
| Backend exists, build UI | `/api-to-ui` |
| Single endpoint | `/fastapi-endpoint` |
| New model only | `/fastapi-model` |
| Add a permission | `/fastapi-permission` |
| Form with validation | `/react-form` |
| Complete frontend feature | `/react-feature` |

---

## Notes

- Skills are starting points, not final products. Always read what's generated, refine prompts, iterate.
- Skills implement patterns documented in `docs/FULLSTACK_WORKFLOW.md`, `backend/docs/FEATURE_WORKFLOW.md`, and `frontend/docs/FEATURE_WORKFLOW.md`. Read those guides to understand **why** the generated code looks the way it does.
- For pattern reference (deeper than this index but more readable than `SKILL.md`): see `backend/docs/prompts/backend-patterns.md` and `frontend/docs/prompts/frontend-patterns.md`.

---

**Last updated**: 2026-04-28 (trimmed from 913L narrative to one-paragraph index per [CLN-9 in the cleanup audit](audits/claude-cleanup-audit-2026-04-28.md))
