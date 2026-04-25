# Claude Code Setup Audit — 2026-04-25 (Follow-up)

**Repo**: `saas-boilerplate` (monorepo con submódulos git)
**Branch**: `chore/claude-alignment-2026-04-25`
**Auditor**: Claude (Opus 4.7), plan-mode read-only audit con 1 Explore agent backend + 1 Explore agent frontend en paralelo + verificación directa de findings.
**Audit anterior**: `docs/audits/claude-setup-audit-2026-04-25.md` (mismo día, primera pasada).

---

## Context

Este audit es un **follow-up** del primero del 2026-04-25. La primera pasada produjo un plan (`docs/plans/claude-setup-alignment.md`) que se ejecutó casi por completo: 15 commits sobre la rama cierran los 3 CRITICAL del audit original (SECRET_KEY validator, init_postgres removido, CLAUDE.md saneado) y la mayoría de los HIGH/MED.

**Por qué este follow-up**: el usuario pidió una pasada fresca para detectar (a) drift que apareció DESPUÉS de la primera ronda, (b) gaps que quedaron pendientes y (c) cosas que el target "best practices Claude Code 2026" cubre y que la pasada original no abordó. El objetivo es dejar el repo en un estado donde futuras sesiones de Claude operen como senior engineer que ya conoce el proyecto, sin tener que redescubrir todo cada vez.

---

## 1. Stack confirmado (sin cambios)

- **Backend**: FastAPI ≥0.115 / SQLAlchemy 2 async ≥2.0.35 / Pydantic v2 ≥2.9 / Alembic ≥1.13 / pytest+factory-boy / Ruff + MyPy strict / **uv**. Sin Stripe/Polar/payments.
- **Frontend**: React 18.3 / Vite 5 / TS 5.4 / TanStack Query 5 / Zustand 4 / RHF + Zod / Axios / shadcn/ui (14 componentes) / Vitest + RTL + MSW / **npm**.
- **Infra**: Docker Compose, PostgreSQL 16 + MongoDB 7. Auth via httpOnly cookies (migración 2026-02-06).

⚠️ El boilerplate **no es** Next.js / Drizzle / Stripe / pnpm / Server Actions / Polar — es REST FastAPI + cliente React. Cualquier remediation se adapta a ese stack real.

---

## 2. Estado actual de la config para AI — VERIFICADO archivo por archivo

| Componente | Estado | Evidencia |
|---|---|---|
| `CLAUDE.md` (root, 193L) | ✅ lean, healthy | Multi-tenancy gap en `:108-113`, path-scoped rules en `:115-120`, commit convention en `:122-135`. |
| `backend/CLAUDE.md` (280L) | ✅ detallado | Cross-cutting docs y refs a audits. |
| `frontend/CLAUDE.md` (208L) | ✅ sin info desactualizada | Mención correcta de "no client-side auto-refresh" + warning explícito contra localStorage. |
| `AGENTS.md` | ✅ existe | Espejo tool-agnostic. |
| `.claude/settings.json` | ⚠️ wired pero con refs stale | `permissions` allow/ask/deny presente (`:240-271`), `hooks` cableados (`:272-289`). PERO `references` (líneas 232-238) apunta a paths que NO existen. |
| `.claude/settings.local.json` | ⚠️ mínimo | Solo `Bash(find:*)`. Aceptable. |
| `.mcp.json` | ✅ project-scoped | Context7 únicamente. |
| `.claude/agents/` | ✅ 5 subagents | code-reviewer, security-reviewer, test-writer, db-architect, codebase-explorer. |
| `.claude/skills/` (root) | ✅ post-cleanup | 3 skills (api-to-ui, backend-first, fullstack-feature) cada uno con `<name>/SKILL.md`. **Los `.skill` zip duplicados se removieron en este follow-up** (commit `chore(claude): remove duplicate .skill zip artifacts`). |
| `.claude/hooks/` | ✅ 2 hooks | `protect-files.sh`, `scan-secrets.sh`. `protect-bash.sh` revertido por decisión del usuario. |
| `.claude/commands/` | ✅ /catchup, /ship | — |
| `.claude/rules/` | ✅ 3 rules path-scoped | backend-data-layer, backend-migrations, frontend-api. |
| `.gitignore`, `.worktreeinclude` | ✅ | Cubren worktrees + CLAUDE.local. |
| `docs/audits/`, `docs/plans/` | ✅ con README c/u | — |
| `docs/gotchas.md` | ✅ template + 2 entries reales | Auth migration + multi-tenancy gap. |

---

## 3. Estado actual de patrones de código — VERIFICADO

### Backend

| Patrón | Estado | Evidencia |
|---|---|---|
| Repository pattern | ✅ | Endpoints reciben repo via `Depends(...)`. |
| Service layer (sin HTTPException directo) | ✅ | `ExpectedError` mapeado en `app/api/handlers.py`. |
| Multi-tenancy (Organization model) | 🔴 NO IMPLEMENTADO (decisión de scope) | Documentado en CLAUDE.md root + gotchas + rule data-layer. Tests `test_cross_user_leak.py` cubren regresión. |
| `init_postgres()` removido | ✅ | `backend/app/main.py:135` con comentario explicando por qué. Alembic owner único. |
| SECRET_KEY validator producción | ✅ | `backend/app/config.py:101-116` (`field_validator` rechaza `dev-secret-key-*` cuando `ENVIRONMENT=production`). |
| Tests cross-user leak | ✅ 3 tests | `tests/integration/test_cross_user_leak.py` (read/update/delete). |
| Tests config validator | ✅ 3 tests | `tests/unit/test_config.py`. |
| Request ID middleware | ✅ | `backend/app/main.py:95-112` (`structlog.contextvars` + `X-Request-ID`). |
| Rate limiting global | ✅ | `120/min`, `1000/h` defaults via SlowAPI (`main.py:89-92, 177-180`). |
| Pre-commit hooks | ✅ | `.pre-commit-config.yaml` con ruff + ruff-format + hygiene. MyPy excluido intencional. |
| Healthcheck | ✅ | `/health` (`main.py:206-213`). |
| Alembic migraciones | ✅ 1 migración | refresh token blacklist. |
| Bearer dual-mode auth | ⚠️ por diseño | `backend/app/api/deps.py:80,142,150,169` — `HTTPBearer()` coexiste con cookies para Swagger compat. |

### Frontend

| Patrón | Estado | Evidencia |
|---|---|---|
| `withCredentials: true` | ✅ | `src/api/client.ts:18`. |
| Interceptor 401/403 sin auto-refresh client-side | ✅ | `src/api/interceptors.ts:39-41,60`. |
| `usePermissions` hook | ✅ | `src/hooks/use-permissions.ts`. |
| `<ProtectedRoute requiredPermissions>` | ✅ | `src/routes/protected-route.tsx:6-9`. |
| `<Can>` component | ✅ existe y se usa | `src/components/can.tsx` + uso en `src/components/layout/sidebar.tsx:4,49`. **CONTRADICE la doc actual** — ver §4 NEW-CRITICAL-1. |
| MSW + setup tests | ✅ | `src/test/setup.ts:8`. |
| Frontend tests | ⚠️ Solo 2 archivos | `data-table.test.tsx` + `login-form.test.tsx`. Cobertura ínfima (gap MEDIUM). |
| eslint-plugin-jsx-a11y | ✅ | `.eslintrc.cjs:8,12` con override para shadcn primitives. |
| ErrorBoundary | ✅ | `src/components/error-boundary.tsx:15`. |
| CI workflow frontend | ✅ | `.github/workflows/ci.yml`. |
| TODOs/FIXMEs | ✅ ninguno | grep limpio. |
| Generated API types | ⚠️ ausente | `src/types/generated/` está vacío — `api.ts` no se generó en esta rama. |
| E2E Playwright | ❌ | No configurado (skipped). |
| Storybook | ❌ | No aplica. |

---

## 4. Riesgos detectados

### 🔴 CRITICAL

#### NEW-CRITICAL-1: Drift entre docs y código sobre `<Can>` component

Hay un componente `<Can>` REAL siendo usado en producción que la documentación AI declara que no existe.

**Evidencia**:
- `frontend/src/components/can.tsx` — existe.
- `frontend/src/components/layout/sidebar.tsx:4` — `import { Can } from '@/components/can'`.
- `frontend/src/components/layout/sidebar.tsx:49` — `<Can key={item.path} perform={item.permission}>` (uso activo).
- `CLAUDE.md:73` declara: *"There is no `<Can>` component."* — **falso**.
- `.claude/agents/code-reviewer.md:26` declara: *"There is no `<Can>` component — flag any reference."* — esto provocaría que el agent flag un componente legítimo.

**Por qué pasó**: el audit anterior asumió la convención preferida (`usePermissions` + `<ProtectedRoute>`) y eliminó la mención de `<Can>` de la doc, pero el componente sigue siendo usado activamente en el sidebar.

**Impacto**: alto. Cualquier futura sesión de Claude que lea CLAUDE.md o invoque al code-reviewer va a producir feedback erróneo (sugerir borrar `<Can>` o re-implementar el sidebar).

**Decisión adoptada en este follow-up**: **Opción B — preservar `<Can>` como patrón canónico**, alinear la doc. `<Can>` es estándar (cerbos/casl-style) y ya está integrado; borrar y reescribir es churn sin beneficio.

### 🟡 HIGH

#### NEW-HIGH-1: `.claude/settings.json` con file refs stale

- `:233` `backend_example`: `backend/app/api/v1/endpoints/users.py` → real `backend/app/api/v1/users.py` (sin subcarpeta `endpoints/`).
- `:235` `model_example`: `backend/app/models/user.py` → real `backend/app/models/postgres/user.py`.
- `:237` `form_example`: `frontend/src/features/auth/components/LoginForm.tsx` → real `login-form.tsx` (kebab-case).

**Impacto**: skills/subagents que dereferencien estos paths van a fallar silenciosamente. Degrada onboarding.

#### NEW-HIGH-2: Skill count mismatch en `CLAUDE.md`

- `CLAUDE.md:26` — *"Backend (5 skills): fastapi-endpoint, fastapi-model, fastapi-migration, fastapi-permission, fastapi-test"*.
- Real: 6 skills (los 5 + `feature-from-plan`). `.claude/settings.json:9-46` y `backend/.claude/skills/` lo confirman.

#### NEW-HIGH-3: `frontend/src/types/generated/api.ts` no committeado

- Directorio `frontend/src/types/generated/` está vacío.
- El rule `frontend-api.md` insiste en usar tipos generados.

**Fix**: documentar `npm run generate:types` como paso obligatorio post-clone en `docs/GETTING_STARTED.md`. Si se quiere commitear, requiere backend levantado al momento del commit.

#### NEW-HIGH-4: ✅ resuelto en este follow-up

Skills root con archivos `.skill` zip duplicando carpetas. **Cerrado** en commit `chore(claude): remove duplicate .skill zip artifacts`.

### 🟢 MEDIUM

#### NEW-MED-1: `user_repo` métodos sin scope filter

- `backend/app/repositories/user_repo.py:69-128` — `get_by_email()`, `get_active_users()`, `get_admins()` sin filtro de scope.
- Gateado por `@require_permissions(Permission.USERS_READ)` en endpoint, pero en sesiones nuevas un developer podría reusarlos sin gate.
- **Fix opcional (no en este pase)**: regression test que verifique 401/403 sin permission.

#### NEW-MED-2: db-architect agent con drift note obsoleta

- `.claude/agents/db-architect.md:33-34` referencia: *"`init_postgres()` in `backend/app/main.py:106-107` currently creates initial schema in dev (bypasses Alembic)"*.
- Pero `init_postgres()` ya fue removido — `main.py:135` tiene comentario explicando la remoción.

**Fix**: reemplazar la drift note por una nota de "Alembic owner único".

#### NEW-MED-3: Frontend test coverage muy baja (2 archivos)

- No bloqueante, no es regresión — el repo siempre estuvo así. Documentar como deuda futura, no remediar en este pase.

#### NEW-MED-4: README.md root extenso (559L)

- Best practices 2026 sugieren < 300L con detalles en `docs/`. No urgente, solo flagging.

---

## 5. Skipped del audit anterior — decisiones vigentes

| ID | Issue | Decisión |
|---|---|---|
| HIGH-1 (orig.) | Sin CI backend | Skipped por usuario. Mantener. |
| HIGH-7 (orig.) | E2E Playwright | Skipped. Sigue como gap futuro. |
| MED-2 (orig.) | Sentry/observability | Skipped — terceros. Mantener. |

---

## 6. Resumen ejecutivo

El boilerplate está **~95% alineado** con best practices Claude Code 2026 (subió desde 80% del audit original). Lo que se decidió ejecutar del plan anterior, se ejecutó. Los 3 CRITICAL del audit anterior están cerrados. Pero apareció un drift NUEVO 🔴: el componente `<Can>` SÍ existe en `frontend/src/components/can.tsx` y se usa en el sidebar — la doc dice lo contrario, lo que envenenaría a futuras sesiones. Hay 4 HIGH menores: `.skill` zips duplicados (ya cerrado en este follow-up), settings.json con 3 paths stale, skill count mismatch en CLAUDE.md, y types generados no committeados. 1 MED relevante: db-architect agent con drift note obsoleta sobre `init_postgres`. Trabajo de cierre estimado ~30-45 min, todo edits chicos sin reescribir lógica.

---

## 7. Fortalezas (NO TOCAR)

- Repository → Service → Endpoint con DI FastAPI.
- Auth: bcrypt + JWT HS256 + refresh rotation con blacklist single-use + httpOnly cookies.
- Multi-DB strategy con ADR (`docs/adr/001-dual-database-strategy.md`).
- structlog con censoring automático de campos sensibles.
- Pre-commit + ruff + mypy strict (mypy en CI/dev, no en commit hook intencional).
- Frontend: feature-based architecture + TanStack Query + Zustand separation correcta.
- Skills cubren stack actual sin redundancia.
- Submodule strategy: backend y frontend con su propio CI/CLAUDE.md/skills locales.

---

## 8. Plan de remediación

Ver `docs/plans/claude-setup-alignment-followup.md` para el plan detallado tier-por-tier (Tier 1 cleanup ya parcialmente ejecutado, Tier 2 edits puntuales).
