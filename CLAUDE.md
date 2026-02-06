# Root Orchestration Context

**Quick Start**: `docker compose up -d` → Backend: http://localhost:8000 | Frontend: http://localhost:5173

This is the **root orchestration layer** connecting backend (FastAPI) and frontend (React) submodules. For detailed context on each layer, see `backend/CLAUDE.md` and `frontend/CLAUDE.md`.

## Monorepo Structure

```
├── backend/ # FastAPI + PostgreSQL + MongoDB (port 8000)
│ ├── CLAUDE.md # Backend context (194 lines)
│ └── docs/ # Backend workflows & patterns
├── frontend/ # React + TypeScript + Vite (port 5173)
│ ├── CLAUDE.md # Frontend context (212 lines)
│ └── docs/ # Frontend workflows & patterns
├── docs/ # Integration & architecture docs
└── CLAUDE.md # THIS FILE - Root orchestration
```

**See**: `README.md` for complete documentation map.

## Claude Code Skills

- **Backend** (5 skills): `fastapi-endpoint`, `fastapi-model`, `fastapi-migration`, `fastapi-permission`, `fastapi-test`
- **Frontend** (5 skills): `react-component`, `react-form`, `api-integration`, `react-feature`, `react-page`
- **Root** (5 skills):
 - Active: `backend-first`, `api-to-ui`, `fullstack-feature`
 - Planned: `api-contract`, `deploy`

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
- **Login**: POST `/api/v1/auth/login` → `{access_token, refresh_token}`
- **Storage**: localStorage (access 30min, refresh 7d)
- **Interceptor**: Request adds Bearer token, Response catches 401 → auto-refresh
- **Backend**: `app/common/dependencies.py:get_current_user()`
- **Frontend**: `src/features/auth/hooks/useAuth.ts`

### Permission System
- **Backend**: `@require_permissions(Permission.USERS_READ)` decorator
- **Frontend**: `<Can permission="USERS_READ">...</Can>` component
- **Sync**: Frontend regenerates types from backend Permission enum

### Chat (Stream Chat Integration)
- **Provider**: Stream Chat (getstream.io) — hosted, no self-managed infrastructure
- **Backend**: `POST /api/v1/chat/token` generates Stream token + upserts user; `GET /api/v1/chat/users` lists available users
- **Frontend**: `src/features/chat/` — uses `stream-chat-react` SDK components
- **Config**: `STREAM_API_KEY` + `STREAM_API_SECRET` in root `.env` (passed via docker-compose)
- **Cost**: Free up to 1,000 MAU, then $399/mo for 10K MAU
- **No database models** — Stream stores all messages and channels

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

## Documentation Map

### Quick Start
- **docs/GETTING_STARTED.md** - New developer setup (145 lines)
- **README.md** - Project overview with all links (200 lines)

### Claude Code Usage
- **docs/CLAUDE_CODE_BEST_PRACTICES.md** - Comprehensive A-I guide (240 lines)
- **docs/prompts/CLAUDE_PROJECT_SETUP.md** - Claude.ai Project setup (180 lines)

### Architecture & Workflows
- **docs/ARCHITECTURE.md** - System design, database strategy, auth flow (220 lines)
- **docs/FULLSTACK_WORKFLOW.md** - E2E feature implementation (270 lines)
- **docs/prompts/integration-patterns.md** - API patterns with code (400 lines)

### Layer-Specific
- **backend/CLAUDE.md** - Backend context (194 lines)
- **backend/docs/** - Backend workflows & patterns
- **frontend/CLAUDE.md** - Frontend context (212 lines)
- **frontend/docs/** - Frontend workflows & patterns

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
