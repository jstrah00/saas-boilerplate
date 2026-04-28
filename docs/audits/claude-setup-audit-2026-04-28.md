# Claude Code Setup Audit — 2026-04-28

**Repo**: `saas-boilerplate` (monorepo con submódulos git)
**Branch**: `chore/claude-alignment-2026-04-25` (rama de alignment, 31 commits sobre `master`)
**Auditor**: Claude (Opus 4.7), 3 exploradores en paralelo (backend, frontend, AI config) + verificación directa de findings.
**Audits previos**:
- `docs/audits/claude-setup-audit-2026-04-25.md` (primera pasada — cerró 3 CRITICAL).
- `docs/audits/claude-setup-audit-2026-04-25-followup.md` (follow-up del mismo día — cerró drift `<Can>`, paths stale, skill count).

Este audit es una **tercera pasada** 3 días después: read-only, busca drift NUEVO o gaps que las dos pasadas anteriores hayan dejado abiertos.

---

## 1. Stack confirmado (sin cambios desde 2026-04-25)

- **Backend**: FastAPI ≥0.115 / SQLAlchemy 2 async ≥2.0.35 / Pydantic v2 ≥2.9 / Alembic ≥1.13 / pytest+factory-boy / Ruff + MyPy strict / **uv**. Sin Stripe/Polar/payments.
- **Frontend**: React 18.3 / Vite 5 / TS 5.4 / TanStack Query 5 / Zustand 4 / RHF + Zod / Axios / shadcn/ui (14 componentes) / Vitest + RTL + MSW / **npm**.
- **Infra**: Docker Compose, PostgreSQL 16 + MongoDB 7. Auth via httpOnly cookies (migración 2026-02-06).

⚠️ El boilerplate **no es** Next.js / Drizzle / Stripe / pnpm / Server Actions / Polar — es REST FastAPI + cliente React. Cualquier remediation se adapta a ese stack real.

---

## 2. Estructura

Sin cambios estructurales desde el follow-up: backend y frontend mantienen su layout (api/v1, models/postgres, models/mongodb, repositories, services, schemas, common; src/api, src/features/{auth,items,profile,users}, src/components, src/routes, src/store, src/hooks, src/types). Ningún archivo movido o renombrado en los últimos 3 días.

---

## 3. Estado actual de la config para AI — verificado archivo por archivo

| Componente | Estado | Notas |
|---|---|---|
| `CLAUDE.md` (root) | ✅ lean (193L), accurate | Multi-tenancy gap doc, path-scoped @-refs, commit convention. Sin drift detectado. |
| `backend/CLAUDE.md` | 🔴 con drift NUEVO | Endpoint code example usa `from app.common.dependencies import ...` pero el path real es `app.api.deps`. Ver §4 NEW-CRIT-C. |
| `frontend/CLAUDE.md` | ✅ accurate | Auth flow, permission gates (`<ProtectedRoute>`, `<Can>`, `usePermissions`) y rutas docs verificadas. |
| `AGENTS.md` | ✅ thin pointer (16L) | Coherente con CLAUDE.md root; sin divergencia. |
| `.claude/settings.json` | ✅ wired | Permissions allow/ask/deny + hooks cableados. `references` block: todos los paths resuelven (post-fix `310dacb`). |
| `.claude/settings.local.json` | ✅ mínimo | Solo `Bash(find:*)`. Aceptable. |
| `.mcp.json` | ✅ project-scoped | Context7 únicamente — sensato para este stack. |
| `.claude/agents/` (5) | ✅ | code-reviewer, codebase-explorer, db-architect, security-reviewer, test-writer. `code-reviewer` actualizado para tratar `<Can>` como canónico. `db-architect` post-fix `6d63b89` (sin drift `init_postgres`). |
| `.claude/skills/` (root, 3) | ✅ | api-to-ui, backend-first, fullstack-feature. Sin `.skill` zips leftover. |
| `.claude/hooks/` (2) | 🟡 con gap | `protect-files.sh` y `scan-secrets.sh` ejecutables y wired. Pero `scan-secrets.sh` no detecta keys Anthropic/OpenAI — ver §4 NEW-HIGH-A. |
| `.claude/commands/` (3) | ✅ | catchup, ship, audit-claude-setup. El último intencionalmente en español (autor es ES-native). |
| `.claude/rules/` (3) | 🔴 con drift | `backend-migrations.md:19-21` aún referencia `init_postgres()` removido. Ver §4 NEW-CRIT-B. |
| `.gitignore` + `.worktreeinclude` | ✅ | Cubren `.claude/worktrees/`, `CLAUDE.local.md`, `.env`. |
| `docs/audits/`, `docs/plans/` | ✅ | Cada uno con README + entries previos. |
| `docs/gotchas.md` | ✅ | Template + 2 entries reales. |
| README.md root (16.7KB / ~559L) | 🟢 pre-existing flag | Largo; ya señalado en NEW-MED-4 del follow-up. Sin acción urgente. |

---

## 4. Riesgos detectados

### 🔴 CRITICAL

#### NEW-CRIT-A — `backend/alembic/env.py` no importa `RefreshTokenBlacklist`

**Evidencia**:
- `backend/alembic/env.py:33` — `from app.models.postgres import user, item  # noqa: F401`. **Falta** `refresh_token_blacklist`.
- `backend/app/models/postgres/__init__.py:37` — exporta `RefreshTokenBlacklist` (existe el modelo).
- `backend/alembic/versions/2026_02_06_1917-c756768ae27e_add_refresh_token_blacklist_table.py` — la migración existe.
- `backend/CLAUDE.md` Critical Gotchas explícito: *"Alembic: MUST import models in `alembic/env.py` or autogeneration fails"*. **El propio CLAUDE.md viola su propia regla**.

**Impacto**: si alguien modifica `RefreshTokenBlacklist` (agregar columna, cambiar tipo, agregar índice), `alembic revision --autogenerate` **NO** detecta el cambio. Sale a prod sin migración. Riesgo de schema drift real. Además, próximas sesiones de Claude que sigan la regla `backend-migrations.md` ("autogenerate only, autogenerate confiable") generarán migraciones vacías sin avisar.

**Fix propuesto** (Tier 3, 1 línea):
```python
# backend/alembic/env.py:33
from app.models.postgres import user, item, refresh_token_blacklist  # noqa: F401
```

**Test de regresión sugerido**: agregar un test que ejecute `alembic check` (o equivalente) en CI, para que cualquier futura ausencia de import se detecte.

---

#### NEW-CRIT-B — `.claude/rules/backend-migrations.md` referencia función que ya no existe

**Evidencia**:
- `.claude/rules/backend-migrations.md:19-21` — bloque "Initial-schema drift note":
  > *"`init_postgres()` in `backend/app/main.py:106-107` currently creates initial schema directly in dev. This bypasses Alembic and risks drift in prod."*
- `backend/app/main.py:106` — actualmente es `structlog.contextvars.bind_contextvars(...)`, no schema init.
- `backend/app/main.py:135` — comentario explícito *"`init_postgres()` removed; Alembic owns schema in all envs"*.
- Esta drift fue detectada y FIXEADA para `.claude/agents/db-architect.md` en el commit `6d63b89` (NEW-MED-2 del follow-up), pero `backend-migrations.md` quedó sin tocar.

**Impacto**: cuando una sesión de Claude edite migraciones, esta rule se carga vía path-scope. La sección "drift note" la lleva a buscar una función que no existe, lo cual desestabiliza su modelo mental: "¿qué más de esta rule está stale?". También contradice el comentario de `main.py:135` ("Alembic owns schema") y la línea anterior de la rule que confirma "autogenerate only".

**Fix propuesto** (Tier 1, ~3 líneas): reemplazar el bloque por:
> *"Alembic es owner único del schema en TODOS los environments (dev/staging/prod). `init_postgres()` ya no existe — fue removido en la rama de alignment 2026-04-25 para evitar drift dev→prod. Cualquier modelo nuevo necesita su migración. Si en el futuro vuelves a ver schema-creation directo, es regresión."*

---

#### NEW-CRIT-C — `backend/CLAUDE.md` endpoint example importa de path inexistente

**Evidencia**:
- `backend/CLAUDE.md` paso 6 (Endpoint, "7-Step Workflow"): el ejemplo de código incluye:
  ```python
  from app.common.dependencies import get_db, get_current_user
  ```
- El path real es `backend/app/api/deps.py` (confirmado por root `CLAUDE.md`, `.claude/rules/backend-data-layer.md` y `.claude/agents/code-reviewer.md`).
- El audit del 2026-04-25 (CRITICAL-3) ya identificó esta misma drift en el ROOT `CLAUDE.md` y la fixeó (commit `391ffa5`). **Pero el backend `CLAUDE.md` quedó con la versión vieja**. Ni el audit original ni el follow-up lo cubrieron.

**Impacto**: alto. El skill `/fastapi-endpoint` y el workflow de 7 pasos son los caminos canónicos para crear endpoints. Cualquier sesión nueva que siga el workflow va a copiar el import incorrecto. Frustración inmediata: el código no compila, Claude pierde tiempo (y context window) buscando dónde está realmente `get_current_user`. Además contamina el modelo mental: el dev junior que use Claude para aprender el repo internaliza el path incorrecto.

**Fix propuesto** (Tier 2, edit puntual al snippet): cambiar la línea por:
```python
from app.api.deps import get_current_user
from app.db.postgres import get_db  # si es PostgreSQL
```
(verificar el path exacto de `get_db` en `app/db/postgres.py` o donde esté).

---

### 🟡 HIGH

#### NEW-HIGH-A — `scan-secrets.sh` no detecta keys de Anthropic ni de OpenAI

**Evidencia**:
- `.claude/hooks/scan-secrets.sh` cubre patterns para AWS (`AKIA`), Stripe (`sk_|pk_|rk_` con underscore), JWT, Telegram, PEM, GitHub, Slack.
- **No cubre**:
  - Anthropic API keys: prefijo `sk-ant-api03-...` (dash, no underscore — el pattern Stripe `sk_` no matchea).
  - OpenAI API keys: prefijo moderno `sk-proj-...` o legacy `sk-...` (dash; mismo problema).

**Impacto**: este es un boilerplate explícitamente para usar con Claude Code (¡el comando `/audit-claude-setup` está literalmente acá!). Es altamente probable que un developer pegue un curl de ejemplo de la docs de Anthropic o un snippet de OpenAI en un prompt para debugging. El hook no lo bloquea, las keys terminan logueadas en el transcript de Claude → riesgo de exfil si el transcript se comparte.

**Fix propuesto** (Tier 1, ~6 líneas adicionales al script):
```bash
# Anthropic API key
if grep -qE 'sk-ant-(api|oat)[0-9]{2}-[A-Za-z0-9_-]{20,}' "$INPUT_FILE"; then
  echo "BLOCKED: Anthropic API key detected" >&2
  exit 2
fi
# OpenAI API key (modern + legacy)
if grep -qE 'sk-(proj-)?[A-Za-z0-9_-]{20,}' "$INPUT_FILE"; then
  echo "BLOCKED: OpenAI API key detected" >&2
  exit 2
fi
```

⚠️ El regex de OpenAI puede matchear false positives — testear contra secrets reales antes de commitear.

---

### 🟢 MEDIUM

#### NEW-MED-A — `backend/CLAUDE.md` Critical Gotchas: "401 errors → verify `Authorization: Bearer <token>` header format"

**Evidencia**: `backend/CLAUDE.md` sección "Common Errors → Security" instruye verificar el header `Authorization: Bearer ...`. Pero el sistema migró a httpOnly cookies en 2026-02-06; Bearer es **dual-mode** (Swagger compat) pero **no** el camino primario.

**Impacto**: bajo — la guidance no es FALSA (Bearer sigue funcionando) pero es engañosa para devs que ven 401 desde el frontend, donde la causa real es cookie no enviada (`withCredentials`, CORS, sameSite, etc.).

**Fix sugerido** (opcional, Tier 2): expandir el bullet:
> *"401 errors → en frontend (httpOnly cookies, default): verificar `withCredentials: true`, CORS allow-credentials, sameSite. En API directa / Swagger (Bearer dual-mode): verificar formato `Authorization: Bearer <token>`."*

#### NEW-MED-B — README.md root (16.7KB / ~559L)

Pre-existing flag del follow-up (NEW-MED-4). Sin acción en este pase.

#### NEW-MED-C — Frontend test coverage muy baja (2 archivos)

Pre-existing flag del follow-up (NEW-MED-3). El boilerplate siempre estuvo así. Sin acción en este pase.

---

### Informational (no es drift, está bien)

- `.claude/commands/audit-claude-setup.md` está en español. Esto es **intencional** — el autor del repo es hispano (`julian@akua.la`) y los comandos son ergonomía personal. No flag.
- `frontend/src/types/generated/api.ts` ausente del repo. Es **intencional** — se regenera post-clone via `npm run generate:types`. Cubierto por la rule `frontend-api.md` y `docs/GETTING_STARTED.md`. No flag.
- Bearer dual-mode en `backend/app/api/deps.py`. **Intencional** — Swagger UI compat. Documentado.
- `dev-secret-key-*` placeholder en `backend/.env.example`. **Intencional** + bloqueado por validator de Pydantic en producción (`backend/app/config.py:101-116`).

---

## 5. Estado de patrones de código (delta vs follow-up)

### Backend
| Patrón | Estado | Cambio vs 2026-04-25 |
|---|---|---|
| Repository → Service → Endpoint | ✅ | sin cambios |
| Multi-tenancy (Organization model) | 🟡 documented gap | sin cambios — sigue intencional |
| Tests cross-user leak | ✅ 3 tests | sin cambios |
| SECRET_KEY validator producción | ✅ | sin cambios |
| Request ID middleware | ✅ | sin cambios |
| Rate limiting global | ✅ 120/min, 1000/h | sin cambios |
| Pre-commit hooks | ✅ ruff lint+format+hygiene | sin cambios |
| Alembic env.py imports completos | 🔴 INCOMPLETO | **NEW finding** — falta `refresh_token_blacklist` |
| HTTPException solo en handlers | ✅ | sin cambios |
| `init_postgres` removido | ✅ | sin cambios |

### Frontend
| Patrón | Estado | Cambio vs 2026-04-25 |
|---|---|---|
| `withCredentials: true` | ✅ | sin cambios |
| Interceptor 401/403 sin auto-refresh | ✅ | sin cambios |
| `<Can>` + `<ProtectedRoute>` + `usePermissions` canónicos | ✅ | sin cambios |
| Hand-rolled `permissions.includes` | ✅ zero | sin cambios |
| Direct `fetch()` calls | ✅ zero | sin cambios |
| `localStorage` solo i18n+theme | ✅ | sin cambios |
| jsx-a11y plugin + shadcn override | ✅ | sin cambios |
| Generated types ausentes (intencional) | ✅ | sin cambios |
| Test coverage | 🟢 bajo (2 archivos) | sin cambios |

**Frontend submodule**: clean bill of health — cero drift desde 2026-04-25.

---

## 6. Inventario de gaps vs target (best practices Claude Code 2026)

| Componente target | Estado | Acción propuesta |
|---|---|---|
| `CLAUDE.md` lean (<400L) con @-refs | ✅ root 193L | NO tocar |
| `backend/CLAUDE.md` accuracy | 🔴 endpoint snippet stale | Tier 2 fix import path |
| `frontend/CLAUDE.md` accuracy | ✅ | NO tocar |
| Subagents (`.claude/agents/`) | ✅ 5 actualizados | NO tocar |
| Path-scoped rules (`.claude/rules/`) | 🔴 backend-migrations.md drift `init_postgres` | Tier 1 fix |
| Hooks completos | 🟡 falta Anthropic/OpenAI scan | Tier 1 ampliar `scan-secrets.sh` |
| Alembic env.py imports completos | 🔴 falta 1 modelo | Tier 3 fix de 1 línea + (opcional) test de regresión |
| Skills | ✅ 14 skills | NO tocar |
| `.mcp.json` | ✅ context7 | NO tocar |
| `docs/gotchas.md` | ✅ template + entries | NO tocar |
| Multi-tenancy real | 🟡 fuera de scope | mantener como gap documentado |
| CI backend | ⏭ skipped por usuario | mantener decisión |
| E2E Playwright | ⏭ skipped | mantener decisión |
| Sentry / observability | ⏭ skipped | mantener decisión |

---

## 7. Resumen ejecutivo

El boilerplate está **~96% alineado** (subió desde 95% del follow-up). Tres hallazgos NUEVOS reales en 3 días:

1. 🔴 **Alembic env.py** olvida importar `RefreshTokenBlacklist` — riesgo concreto de schema drift, además viola el propio "Critical Gotcha" del backend CLAUDE.md.
2. 🔴 **`backend-migrations.md` rule** sigue mencionando `init_postgres()` que ya fue removido — la misma drift que se cerró en `db-architect.md` el 25/04 quedó abierta acá.
3. 🔴 **`backend/CLAUDE.md` endpoint snippet** importa de `app.common.dependencies` (path inexistente) — el follow-up del 25/04 fixeó la misma drift en el ROOT pero olvidó el backend.

1 🟡 **HIGH**: `scan-secrets.sh` no detecta keys Anthropic/OpenAI — gap relevante para un boilerplate orientado a Claude Code.

Trabajo de cierre estimado **~20 min**, todo edits chicos en archivos de config + 1 línea de código real (`alembic/env.py`).

---

## 8. Fortalezas (NO TOCAR)

- Repository → Service → Endpoint pattern sólido.
- Auth: bcrypt + JWT HS256 + refresh rotation con blacklist single-use + httpOnly cookies.
- structlog con censoring automático.
- SECRET_KEY validator producción + cross-user leak tests.
- 5 subagents focused, sin redundancia. `code-reviewer` y `db-architect` ya updated en el follow-up.
- 14 skills cubren stack actual sin duplicación.
- Frontend: zero drift detectado en 3 días — patterns honrados consistentemente.
- Submodule strategy con CI/CLAUDE.md/skills locales.
- Hooks `protect-files.sh` y `scan-secrets.sh` ejecutables y wired correctamente.

---

## 9. Plan de remediación

Ver `docs/plans/claude-setup-alignment-2026-04-28.md` (a generar en Fase 2 del audit).

Estructura tentativa:
- **Tier 1** (cleanup AI config, zero risk): fix `backend-migrations.md` rule + ampliar `scan-secrets.sh`.
- **Tier 2** (edit puntual a backend/CLAUDE.md): corregir import path en endpoint snippet.
- **Tier 3** (1 línea de código + test opcional): añadir import en `backend/alembic/env.py`.
