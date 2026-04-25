# Claude Code Setup Audit — 2026-04-25

**Repo**: `saas-boilerplate` (monorepo con submódulos git)
**Auditor**: Claude (Opus 4.7) read-only audit con 3 exploradores en paralelo + verificación directa de findings CRITICAL.
**Scope**: estado de config AI/Claude + patrones de código del backend FastAPI + frontend React, evaluado contra best practices Claude Code 2026.

---

## 1. Stack detectado

### Backend (`backend/`, submódulo → github.com/jstrah00/fastapi-boilerplate)
| Capa | Tecnología | Versión |
|---|---|---|
| Runtime | Python | `>=3.12` |
| Framework | FastAPI | `>=0.115.0` |
| ORM | SQLAlchemy (async) | `>=2.0.35` |
| Migrations | Alembic | `>=1.13.0` |
| Validation | Pydantic | `>=2.9.0` |
| Auth | python-jose + passlib[bcrypt] | `>=3.3.0` / `>=1.7.4` |
| Rate limiting | slowapi | `>=0.1.9` |
| Logging | structlog | (pinned vía uv.lock) |
| Tests | pytest + pytest-asyncio + pytest-cov | `>=8.3.0` |
| Factories | factory-boy + Faker | `>=3.3.0` |
| Linter / formatter | Ruff | `>=0.7.0` |
| Type checker | MyPy (strict mode) | `>=1.13.0` |
| Package manager | **uv** (NO pip, NO poetry) | — |
| Payments | **NONE** (no Stripe, no Polar) | — |
| DBs | PostgreSQL 16 (primaria) + MongoDB 7 (opcional) | — |

### Frontend (`frontend/`, submódulo → github.com/jstrah00/frontend-boilerplate)
| Capa | Tecnología | Versión |
|---|---|---|
| UI | React | 18.3.1 |
| Bundler | Vite | 5.1.6 |
| Lang | TypeScript | 5.4.2 |
| Server state | TanStack Query | 5.28.0 |
| Client state | Zustand | 4.5.2 |
| Routing | React Router | 6.22.0 |
| Forms | react-hook-form + Zod | 7.51.0 / 3.22.4 |
| HTTP | Axios | 1.6.7 |
| Components | shadcn/ui (Radix) | 14 components |
| i18n | react-i18next | 14.1.0 (en, es) |
| Tests | Vitest + RTL + MSW | 1.3.1 / 14.2.1 / 2.12.7 |
| Type-gen | openapi-typescript | (script en `scripts/generate-api-types.ts`) |
| Package manager | **npm** (`package-lock.json`) | — |

### Root
- Docker Compose orquesta backend + frontend + postgres + mongo + (opcional) pgadmin + mongo-express.
- Submódulos git apuntan a master de cada repo.

---

## 2. Estructura

**Layout**: monorepo de orquestación (no es un workspace npm/pnpm; los submódulos son repos independientes).

```
saas-boilerplate/
├── backend/                       (submódulo, FastAPI)
│   ├── app/
│   │   ├── api/v1/                routers (auth, users, items)
│   │   ├── api/deps.py            ← get_current_user (linea 138-219)
│   │   ├── api/handlers.py        global exception handlers
│   │   ├── common/                permissions, security, exceptions, logging
│   │   ├── models/postgres/       SQLAlchemy: user, item, refresh_token_blacklist
│   │   ├── models/mongodb/        Beanie: document
│   │   ├── repositories/          base + user_repo + item_repo
│   │   ├── services/              auth_service, user_service, item_service
│   │   ├── schemas/               Pydantic (auth, user, item)
│   │   └── db/                    postgres + mongodb conexión
│   ├── alembic/versions/          1 sola migración (refresh blacklist)
│   ├── tests/                     unit + integration (2 archivos)
│   └── .claude/skills/            6 skills (fastapi-*)
├── frontend/                      (submódulo, React+Vite)
│   ├── src/
│   │   ├── api/                   client, endpoints, interceptors
│   │   ├── features/              auth, users, items, profile (feature-based)
│   │   ├── components/ui/         shadcn (14)
│   │   ├── components/layout/     app-layout, sidebar, header
│   │   ├── routes/                router + protected-route
│   │   ├── store/                 Zustand auth + UI slices
│   │   ├── hooks/                 use-permissions, etc.
│   │   ├── types/generated/       OpenAPI types (auto-gen)
│   │   └── i18n/                  config + locales/{en,es}
│   ├── .github/workflows/ci.yml   ✅ CI configurado
│   └── .claude/skills/            5 skills (react-*)
├── docs/                          18 docs cross-cutting
├── .claude/                       settings.json + 3 skills root
└── CLAUDE.md                      orchestration root (157 líneas)
```

---

## 3. Estado actual de la config para AI

| Componente | Estado | Notas |
|---|---|---|
| `CLAUDE.md` (root) | ⚠️ Bien estructurado pero con info DESACTUALIZADA | 157L. Headers OK. Pero líneas 64-67, 66, 71, 11, 14 contienen errores fácticos (ver §5). |
| `backend/CLAUDE.md` | ✅ Detallado, focused | 250L. 7-step workflow + RBAC + gotchas. Sin gap de exactitud. |
| `frontend/CLAUDE.md` | ✅ Bien | 200L. Patterns de state/forms/auth/routing/i18n. |
| `AGENTS.md` | ❌ Ausente | Sin espejo tool-agnostic. |
| `.claude/settings.json` (root) | ⚠️ 233L pero sin guardrails | Define monorepo, skills, docs, ports. **NO hooks. NO permissions allow/ask/deny granulares.** |
| `.claude/settings.local.json` | ⚠️ Mínimo | Solo `Bash(find:*)`. Sin deny rules. |
| `.mcp.json` | ❌ Ausente | Ningún MCP server configurado. |
| Subagents (`.claude/agents/`) | ❌ Ausente | Ningún subagent definido. |
| Skills (`.claude/skills/`) | ✅ 14 skills bien organizados | 3 root (orchestrators), 6 backend, 5 frontend. Sin redundancia. |
| Hooks (`.claude/hooks/`) | ❌ Ausente | Sin protect-bash, protect-files, scan-secrets, typecheck-on-stop. |
| Path-scoped rules (`.claude/rules/`) | ❌ Ausente | Sin rules contextuales por path (data layer, migrations, api). |
| Slash commands (`.claude/commands/`) | ❌ Ausente | Sin `/catchup`, `/ship`, etc. |
| `docs/` cross-cutting | ✅ Exhaustivo | ARCHITECTURE, FULLSTACK_WORKFLOW, GETTING_STARTED, PERMISSIONS, SKILLS_REFERENCE, TROUBLESHOOTING, CLAUDE_CODE_BEST_PRACTICES, ADRs, prompts/. |
| `backend/docs/` | ✅ | FEATURE_WORKFLOW, TESTING, prompts/backend-patterns. |
| `frontend/docs/` | ✅ | FEATURE_WORKFLOW, TESTING, prompts/frontend-patterns. |
| `IMPLEMENTATION_SUMMARY.md` (root) | ⚠️ Stale-ish | Changelog del 2026-02-06 sobre auth → httpOnly cookies. Vive en root, contamina contexto inicial. |
| `.gitignore` (root) | ⚠️ Mínimo | Solo `.env`. Sin `.claude/worktrees/`, sin `CLAUDE.local.md`. |
| Otras herramientas (Cursor/Windsurf/Copilot) | ✅ Limpio | Sin `.cursorrules`, `.windsurfrules`, `copilot-instructions.md`. |

---

## 4. Estado actual de patrones del código

| Patrón | Estado | Evidencia (file:line) |
|---|---|---|
| Repository pattern centralizado | ✅ | `backend/app/repositories/base.py`, `item_repo.py`, `user_repo.py` |
| Service layer separado | ✅ | `backend/app/services/auth_service.py`, `user_service.py`, `item_service.py` |
| Pydantic schemas con `from_attributes=True` | ✅ | `backend/app/schemas/*.py` |
| Multi-tenant isolation (org_id en queries) | 🔴 NO IMPLEMENTADO | `app/models/postgres/user.py:74` (comentario "For multi-tenant applications" sin código), `app/models/postgres/item.py:85` (solo `owner_id`), `app/repositories/item_repo.py:83-98` (filtra solo por owner) |
| Modelo Organization/Tenant | 🔴 Ausente | No existe en `app/models/postgres/` |
| `get_current_organization` dep | 🔴 Ausente | No existe en `app/api/deps.py` |
| ActionResult / error envelope | ✅ | Exception hierarchy en `app/common/exceptions.py:54-172`, handlers en `app/api/handlers.py:66-228` |
| Migraciones inmutables auto-generadas | ⚠️ Parcial | Solo 1 migración en `alembic/versions/`. Schema inicial via `init_postgres()` en `main.py:106-107`, NO via Alembic. Risk de drift. |
| Idempotencia en webhooks | N/A | No hay webhooks (no payments). |
| Soft delete pattern | ✅ | `Item.status` field (item.py:92-97), `BaseRepository.soft_delete()` |
| Test factories | ✅ | factory-boy en deps |
| Cross-tenant tests | 🔴 Ausentes | No hay tests de aislamiento (sería N/A para tenant, pero tampoco hay cross-user test) |
| Cross-user isolation tests | 🔴 Ausentes | Crítico: nadie verifica que user A no lee items de user B |
| Rate limiting | ⚠️ Solo en login | `app/api/v1/auth.py:86` (5/min). Resto sin throttle. |
| JWT + refresh token rotation | ✅ | `app/services/auth_service.py:167-289`, single-use enforced línea 232-242 |
| bcrypt password hashing | ✅ | passlib via security module |
| RBAC con decoradores | ✅ | `Permission` enum + `require_permissions()` en `app/common/permissions.py:68-383` |
| Structured logging + sensitive censoring | ✅ | structlog en `app/common/logging.py:71-140`, censura `password`/`token`/`secret`/`authorization`/`api_key` |
| Telegram alerts en CriticalError | ✅ | `app/common/alerts.py` |
| Sentry / observability completa | ❌ | No configurado. |
| Request ID middleware | 🟡 Ausente | Sin tracing por request. |
| OpenAPI types regenerados en frontend | ✅ | `frontend/scripts/generate-api-types.ts:1-36`, script `npm run generate:types` |
| Auth via httpOnly cookies | ✅ | `frontend/src/api/client.ts:16-22` (`withCredentials: true`); migración documentada en `IMPLEMENTATION_SUMMARY.md` |
| Permission check en frontend | ✅ vía hook | `frontend/src/hooks/use-permissions.ts:1-24` (`hasPermission`, `hasAllPermissions`, `hasAnyPermission`); `<ProtectedRoute requiredPermissions={[...]}>` en `frontend/src/routes/protected-route.tsx:11-24`. **NOTA**: NO existe `<Can>` component pese a que CLAUDE.md root lo menciona. |
| react-hook-form + Zod resolver | ✅ Consistente | Ej `features/auth/schemas/login.schema.ts:1-9` |
| Code splitting (React.lazy) | ✅ | `frontend/src/routes/index.tsx:1-14` |
| Conventional commits | 🟡 Inconsistente | `git log` muestra mezcla: `feat:`, `claude improved...`, `improve docs`. |
| CI backend | 🔴 Ausente | No hay `backend/.github/workflows/`. |
| CI frontend | ✅ | `frontend/.github/workflows/ci.yml`: lint + test + build + docker. |
| Pre-commit hooks | ❌ | Ni en root ni en submódulos. |
| eslint-plugin-jsx-a11y | 🟡 Ausente | `frontend/.eslintrc.cjs` no lo incluye. |
| E2E tests (Playwright) | ❌ | Solo unit/integration con Vitest. |
| MSW disponible | ✅ | dep instalada, no aún cableada en setup. |

---

## 5. Riesgos detectados (ordenados por severidad)

### 🔴 CRITICAL

#### CRITICAL-1: Multi-tenancy NO implementado a nivel de datos
**Evidencia**:
- `backend/app/models/postgres/user.py:74` — comentario "organization_id: For multi-tenant applications" sin código.
- `backend/app/models/postgres/item.py:85-89` — `owner_id` (FK a `users.id`), sin `organization_id`.
- `backend/app/repositories/item_repo.py:66-98` — `get_by_owner` filtra `Item.owner_id == owner_id`, sin filtro de tenant.
- No existe `Organization` model en `app/models/postgres/`.
- No existe `get_current_organization` en `app/api/deps.py`.

**Impacto**: el repo se vende como "SaaS boilerplate multi-tenant" pero la única isolation real es ownership per-user. Cualquier feature que se agregue va a heredar la deuda. Aún más grave: como root `CLAUDE.md` documenta "multi-tenant" sin caveats, Claude en futuras sesiones va a asumir que el patrón existe y va a producir código que omite el filtro.

**Fix elegido en este audit**: documentar el gap explícitamente en `CLAUDE.md` + agregar test de regresión cross-user (user A no puede leer item de user B vía endpoint). NO se implementa Organization model en este pase (fuera de scope de tooling, es feature de producto).

#### CRITICAL-2: SECRET_KEY default en `.env.example` sin validación de producción
**Evidencia**:
- `backend/.env.example:23`: `SECRET_KEY=dev-secret-key-change-in-production-use-openssl-rand-hex-32`
- `backend/app/core/config.py:96`: `SECRET_KEY: str` (sin validator).
- Workflow esperado por dev: `cp .env.example .env && docker compose up`. Si no edita la SECRET_KEY y deployea, va a prod con la key conocida.

**Impacto**: cualquier deployment naive expone JWTs forgeables.

**Fix elegido**: agregar Pydantic field_validator en `Settings` que rechace `SECRET_KEY` empezando con `"dev-secret-key-"` cuando `ENVIRONMENT == "production"`. Test de regresión antes del fix.

#### CRITICAL-3: `CLAUDE.md` root con información desactualizada que contamina contexto
**Evidencia con file:line**:
- `CLAUDE.md:64-67` describe auth flow: "Storage: localStorage (access 30min, refresh 7d)" + "Interceptor: Request adds Bearer token, Response catches 401 → auto-refresh". **Esto es falso desde 2026-02-06**: la migración a httpOnly cookies (documentada en `IMPLEMENTATION_SUMMARY.md`) eliminó localStorage y Bearer header. `frontend/src/api/client.ts:16-22` confirma `withCredentials: true` y comentario explícito "usando HttpOnly cookies".
- `CLAUDE.md:66` referencia `app/common/dependencies.py:get_current_user()`. **Archivo NO existe**. La función real está en `backend/app/api/deps.py:138-219`.
- `CLAUDE.md:71` menciona componente `<Can permission="USERS_READ">...</Can>`. **Componente NO existe**. El patrón real es `usePermissions()` hook + `<ProtectedRoute requiredPermissions={[...]}>`.
- `CLAUDE.md:11,14` reporta "194 lines" y "212 lines" para los CLAUDE.md de submódulos. **Reales: 250 y 200**.

**Impacto**: en una sesión típica, Claude lee root `CLAUDE.md` primero y construye su modelo mental sobre datos falsos. Va a sugerir interceptors con Bearer token, importar `<Can>` que no existe, referenciar archivos que no existen. El contexto se envenena.

**Fix elegido**: rewrite quirúrgico de las secciones afectadas en Tier 2.

### 🟡 HIGH

| ID | Issue | Evidencia |
|---|---|---|
| HIGH-1 | Sin CI backend | `backend/.github/` no existe |
| HIGH-2 | Schema inicial via `init_postgres()`, no Alembic | `backend/app/main.py:106-107` |
| HIGH-3 | Sin pre-commit hooks pese a que CLAUDE.md exige docstrings | — |
| HIGH-4 | Sin tests de aislamiento per-user (user A vs items user B) | `backend/tests/` |
| HIGH-5 | Sin Request ID middleware | `backend/app/main.py` |
| HIGH-6 | Sin `eslint-plugin-jsx-a11y` | `frontend/.eslintrc.cjs:1-20` |
| HIGH-7 | Sin E2E tests | `frontend/` |
| HIGH-8 | Conventional commits inconsistentes | `git log --oneline` |

### 🟢 MEDIUM

| ID | Issue |
|---|---|
| MED-1 | Rate limiting solo en `/login` (5/min); resto de endpoints sin throttling |
| MED-2 | Sin Sentry/New Relic; observabilidad limitada a Telegram alerts en CriticalError |
| MED-3 | `settings.local.json` solo permite `Bash(find:*)` — falta granularity |
| MED-4 | `.gitignore` root no excluye `.claude/worktrees/` ni `CLAUDE.local.md` |
| MED-5 | `IMPLEMENTATION_SUMMARY.md` (11.5 KB) en root contamina contexto inicial — el usuario aprobó borrarlo |

---

## 6. Inventario de gaps vs target (best practices Claude Code 2026)

| Componente target | Estado actual | Acción propuesta |
|---|---|---|
| `CLAUDE.md` lean (<400L) con @-refs | ✅ root 157L, ⚠️ con errores | Tier 2 fix |
| `AGENTS.md` espejo tool-agnostic | ❌ Ausente | Tier 1 crear |
| `.claude/settings.json` con permissions+hooks | ⚠️ Sin hooks | Tier 1 wire |
| `.claude/agents/` (subagents) | ❌ Ausentes | Tier 1: code-reviewer, security-reviewer, test-writer, db-architect, codebase-explorer |
| `.claude/hooks/` | ❌ Ausentes | Tier 1: protect-bash, protect-files, scan-secrets |
| `.claude/rules/` path-scoped | ❌ Ausentes | Tier 1: backend-data-layer, backend-migrations, frontend-api |
| `.claude/commands/` slash commands | ❌ Ausentes | Tier 1: /catchup, /ship |
| `.mcp.json` | ❌ Ausente | Tier 1: context7 |
| `docs/audits/` | ❌ Ausente | Creado en Fase 1 ✅ |
| `docs/plans/` | ❌ Ausente | Tier 1 crear |
| `docs/gotchas.md` | ❌ Ausente | Tier 1 crear template |
| `.gitignore` con worktrees + local | ⚠️ | Tier 1 ampliar |
| `.worktreeinclude` | ❌ Ausente | Tier 1 crear |
| Skills cubriendo flujos | ✅ 14 skills cubren stack | NO tocar |
| CI backend | ❌ Ausente | Tier 2 crear |
| Pre-commit | ❌ Ausente | Tier 2 (opcional) |
| Validation SECRET_KEY en prod | ❌ Ausente | Tier 3 fix con regression test |
| Test cross-user isolation | ❌ Ausente | Tier 3 agregar |
| Multi-tenancy (Organization model) | ❌ Ausente | **Fuera de scope**: solo documentar gap |
| eslint-plugin-jsx-a11y | ⚠️ | Tier 1 si dep ya disponible, Tier 2 si requiere `npm i` |

---

## 7. Fortalezas (no tocar)

- **Auth**: bcrypt + JWT HS256 + refresh token rotation con blacklist single-use. Implementación cuidadosa (`auth_service.py:232-242`).
- **Exception architecture**: jerarquía `ExpectedError`/`CriticalError` con handlers globales y mapeo a HTTP status apropiado.
- **Logging**: structlog con censoring automático de campos sensibles. Output JSON en prod, console en dev.
- **Type safety**: MyPy strict + Pydantic v2 + `from_attributes=True` consistente. Frontend con TypeScript 5.4 strict.
- **Clean architecture**: Repository → Service → Endpoint, con dependency injection FastAPI bien usado.
- **Async-first**: SQLAlchemy 2.0 + asyncio en toda la capa de datos.
- **Frontend**: feature-based architecture, Zustand+Query separation correcta, code-splitting con React.lazy, shadcn/ui (14 componentes), i18n EN/ES, Vitest+MSW listo.
- **Skills**: 14 skills bien orientados al stack (`fastapi-endpoint`, `react-feature`, etc.). NO duplicar.
- **Documentación**: 18 docs cross-cutting + per-layer. Cubre arquitectura, workflows, troubleshooting, permissions, ADRs. Calidad alta.
- **Submodule strategy**: backend y frontend son repos independientes con su propia historia, CI, y `.claude/` local. Buena separación de concerns.

---

## 8. Recomendación

El boilerplate está **80% alineado** con best practices Claude Code 2026. Los 3 gaps CRITICAL son cerrables sin reescribir lógica de negocio:

1. **CRITICAL-1** se cierra con docs + test de regresión (no implementar Organization en este pase).
2. **CRITICAL-2** se cierra con ~5 líneas de validator Pydantic + test.
3. **CRITICAL-3** se cierra con edits quirúrgicos en `CLAUDE.md` root.

Los HIGH son aditivos puros (CI, hooks, rules, subagents) — riesgo zero si se hacen como nuevos archivos. Plan detallado en `/Users/julian/.claude/plans/vas-a-hacer-una-noble-pretzel.md`.

**Estimación de trabajo**: Tier 1 ~30-45 min, Tier 2 ~20 min, Tier 3 ~30 min. Todo reversible commit-por-commit.
