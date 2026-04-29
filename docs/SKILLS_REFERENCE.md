# Skills Reference

Human-readable index of every Claude Code skill in this monorepo. One paragraph per skill plus a link to its full `SKILL.md`. Authoritative metadata (`name`, `description`) lives in each `SKILL.md` frontmatter — this file is the prose companion that Claude Code auto-loads alongside.

**Skills**: 6 backend + 5 frontend = 11.

---

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
└─ Use the per-layer skill that matches the layer you're touching.
   Chain them in order (model → migration → endpoint → test → integration → component → page)
   for a fullstack flow. There is no orchestrator skill — drive the chain yourself.
```

| You need | Skill |
|---|---|
| New endpoint with full layered scaffold | `/fastapi-endpoint` |
| New model only | `/fastapi-model` |
| Database migration | `/fastapi-migration` |
| Add a permission | `/fastapi-permission` |
| Backend tests | `/fastapi-test` |
| Implement a feature from a structured plan | `/feature-from-plan` |
| API client + React Query hooks | `/api-integration` |
| Form with Zod validation | `/react-form` |
| New React component | `/react-component` |
| New page + route | `/react-page` |
| Complete frontend feature folder | `/react-feature` |

---

## Notes

- Skills are starting points, not final products. Always read what's generated, refine prompts, iterate.
- Skills implement patterns documented in `backend/docs/FEATURE_WORKFLOW.md` and `frontend/docs/FEATURE_WORKFLOW.md`. Read those guides to understand **why** the generated code looks the way it does.
- For pattern reference (deeper than this index but more readable than `SKILL.md`): see `backend/docs/prompts/backend-patterns.md` and `frontend/docs/prompts/frontend-patterns.md`.
- Earlier root-level orchestrator skills (`/api-to-ui`, `/backend-first`, `/fullstack-feature`) were removed on 2026-04-28 — they had drifted from the actual stack. Use the per-layer skills above instead.

---

**Last updated**: 2026-04-28
