# Root Orchestration Context

**Quick Start**: `docker compose up -d` → Backend: http://localhost:8000 | Frontend: http://localhost:5173

This is the **root orchestration layer** connecting backend (FastAPI) and frontend (React) submodules. For detailed context on each layer, see `backend/CLAUDE.md` and `frontend/CLAUDE.md`.

## Monorepo Structure

```
├── backend/                # FastAPI + PostgreSQL + MongoDB (port 8000)
│   ├── CLAUDE.md           # Backend context
│   └── docs/               # Backend workflows & patterns
├── frontend/               # React + TypeScript + Vite (port 5173)
│   ├── CLAUDE.md           # Frontend context
│   └── docs/               # Frontend workflows & patterns
├── docs/                   # Integration, architecture, audits, plans
├── .claude/                # Subagents, hooks, rules, skills, slash commands
├── AGENTS.md               # Tool-agnostic pointer to CLAUDE.md
└── CLAUDE.md               # THIS FILE - Root orchestration
```

**See**: `README.md` for complete documentation map.

## Claude Code Skills

Full index with descriptions: [`docs/SKILLS_REFERENCE.md`](docs/SKILLS_REFERENCE.md). Live source of truth: the `SKILL.md` files under `.claude/skills/`, `backend/.claude/skills/`, `frontend/.claude/skills/` (autodetected by Claude Code).

## Development Workflow

### Backend-First (Recommended for Data-Driven Features)
1. Define models & migrations → `backend/docs/FEATURE_WORKFLOW.md`
2. Create endpoints with permissions → Use `fastapi-endpoint` skill
3. Test backend → `pytest backend/tests/`
4. Generate types → `cd frontend && npm run generate:types`
5. Build frontend → `frontend/docs/FEATURE_WORKFLOW.md`
6. Verify integration → Check network tab, permissions, error handling

### Frontend-First (For UI Prototyping)
1. Design components with mock data → `frontend/CLAUDE.md`
2. Build UI flows → Use `react-component`, `react-form` skills
3. Test with Storybook (if available)
4. Design backend contract → Plan endpoints & schemas
5. Implement backend → Use `fastapi-endpoint` skill
6. Connect via API client → Use `api-integration` skill

**See**: `docs/FULLSTACK_WORKFLOW.md` for complete E2E workflows with examples.

## Integration Patterns

### Type Generation
```bash
# Backend exposes OpenAPI schema
curl http://localhost:8000/openapi.json

# Frontend generates TypeScript types
cd frontend && npm run generate:types
# → src/types/generated/api.ts
```

### Authentication Flow

JWT in httpOnly cookies. Backend (`backend/app/api/deps.py:get_current_user` ~L138) reads cookie or `Authorization` header. Frontend (`frontend/src/api/client.ts`) sends cookies via `withCredentials: true`; the login mutation is in `frontend/src/features/auth/hooks/use-login.ts` and resolved permissions land in `frontend/src/store/slices/authSlice.ts`.

**Full flow + token structure + refresh mechanics + security checklist**: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) § Authentication Flow.

### Permission System

Backend enforces with `@require_permissions(Permission.X)` (decorator at API layer, never in services). Frontend has three primitives — pick by surface:
- `<ProtectedRoute>` (`frontend/src/routes/protected-route.tsx`) — route gate.
- `<Can>` (`frontend/src/components/can.tsx`) — JSX gate.
- `usePermissions()` (`frontend/src/hooks/use-permissions.ts`) — programmatic checks.

**Detailed RBAC + security boundary**: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) § Permission System.

### Error Handling
- **Backend**: `app/common/exceptions.py` → HTTP exceptions with detail
- **Frontend**: Interceptor catches errors → Toast notifications (mutations) or inline UI (queries)

**See**: `docs/prompts/integration-patterns.md` for complete patterns with code.

## Critical Gotchas

### Database
- **PostgreSQL** for relational data (users, roles, permissions) - Auto-created via migration
- **MongoDB** for unstructured data (logs, events, flexible schemas) - Manual setup required
- **Don't** mix concerns - see `docs/ARCHITECTURE.md:Dual Database Strategy`

### CORS
- Development: Backend allows `http://localhost:5173`
- Production: Configure `BACKEND_CORS_ORIGINS` in `backend/.env`
- **Don't** use `*` in production

### Ports
- Backend: 8000 | Frontend: 5173 | PostgreSQL: 5432 | MongoDB: 27017
- **Don't** change without updating all docker-compose references

### Type Generation
- Run `npm run generate:types` in frontend/ after backend schema changes
- **Don't** manually edit `src/types/generated/api.ts` (auto-generated)
- **Don't** commit without regenerating types after backend changes

### Permission Checks
- Backend enforces (security boundary)
- Frontend checks for UX only (can be bypassed)
- **Don't** rely solely on frontend checks

### Multi-tenancy: NOT IMPLEMENTED
- The repo is structured as a SaaS boilerplate but does **not** ship an `Organization` / tenant model.
- `Item` is owned per-user via `owner_id` (FK to `users.id`) — see `backend/app/models/postgres/item.py:85`.
- Every query that returns user-scoped data MUST filter by `owner_id`. Cross-user reads are a security bug.
- When `Organization` is introduced, queries must additionally filter by `organization_id`. Add a regression test before that refactor.
- **See**: `docs/audits/claude-setup-audit-2026-04-25.md` (CRITICAL-1) for the full gap.

## Path-scoped rules

Rules referenced by area of the codebase. Read the relevant one before editing files in that path:
- @.claude/rules/backend-data-layer.md — repository/service pattern, ownership filtering.
- @.claude/rules/backend-migrations.md — Alembic autogenerate workflow.
- @.claude/rules/frontend-api.md — generated types, apiClient, httpOnly cookies, query keys.

## Commit convention

Conventional Commits, lightweight. No commitlint enforcement — convention is on the author.

- `feat:` user-visible feature.
- `fix:` bug fix.
- `chore:` tooling, deps, configs, internal moves.
- `docs:` markdown changes only.
- `test:` adds/changes tests only.
- `refactor:` code restructure with no behavior change.
- `ci:` workflow changes (rare here — backend CI is intentionally absent).
- Optional scope in parens: `feat(auth):`, `chore(claude):`, `docs(backend):`.

Sub-commits when bumping a submodule pointer in the super-repo: prefix `chore:` and name what was bumped, e.g. `chore: bump backend submodule for X`.

## Documentation Map

### Quick Start
- **docs/GETTING_STARTED.md** — New developer setup
- **README.md** — Project overview with all links

### Claude Code Usage
- **docs/CLAUDE_CODE_BEST_PRACTICES.md** — Comprehensive A-I guide
- **docs/prompts/CLAUDE_PROJECT_SETUP.md** — Claude.ai Project setup

### Architecture & Workflows
- **docs/ARCHITECTURE.md** — System design, database strategy, auth flow
- **docs/FULLSTACK_WORKFLOW.md** — E2E feature implementation
- **docs/prompts/integration-patterns.md** — API patterns with code

### Audits, Plans & Decisions (3-tier model)
- **`.claude/scratch/{audits,plans}/`** — gitignored ephemeral. Meta-audits about the Claude setup, drift checks, and tactical cleanup plans live here. Borrar libre.
- **`docs/plans/active/`** — committed. Multi-day feature plans worth tracking while in flight. Promote to `docs/adr/` if the plan ships an architectural decision worth preserving; delete on completion.
- **`docs/adr/`** — committed. Permanent architectural decisions (e.g. `001-dual-database-strategy.md`).
- **`docs/gotchas.md`** — running log of real incidents and their fixes.

_Archive_: pre-2026-04-28 audits/plans about the Claude setup itself live in `docs/audits/` and `docs/plans/` (root). Read-only history; new ephemeral work goes to `.claude/scratch/`.

### Layer-Specific
- **backend/CLAUDE.md** — Backend context
- **backend/docs/** — Backend workflows & patterns
- **frontend/CLAUDE.md** — Frontend context
- **frontend/docs/** — Frontend workflows & patterns

## Dev Tools

```bash
# Start all services (detached)
docker compose up -d

# Start with development tools (pgAdmin, mongo-express)
docker compose --profile tools up -d

# View logs
docker compose logs -f [backend|frontend]

# Stop all
docker compose down

# Reset databases
docker compose down -v && docker compose up -d
```

**Access**:
- pgAdmin: http://localhost:5050 (admin@admin.com / admin)
- mongo-express: http://localhost:8081
- API Docs: http://localhost:8000/docs

## Next Steps

1. **New to project?** → Read `docs/GETTING_STARTED.md`
2. **Planning a feature?** → Read `docs/FULLSTACK_WORKFLOW.md`
3. **Using Claude Code?** → Read `docs/CLAUDE_CODE_BEST_PRACTICES.md`
4. **Need architecture details?** → Read `docs/ARCHITECTURE.md`
5. **Writing integration code?** → Read `docs/prompts/integration-patterns.md`
