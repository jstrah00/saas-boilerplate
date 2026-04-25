# Plan: Alinear repo con best practices Claude Code 2026

**Fecha**: 2026-04-25
**Audit fuente**: `docs/audits/claude-setup-audit-2026-04-25.md`
**Plan source**: este archivo + `/Users/julian/.claude/plans/vas-a-hacer-una-noble-pretzel.md`

---

## Resumen ejecutivo

3 gaps 🔴 CRITICAL del audit + 8 gaps 🟡 HIGH se cierran con cambios divididos en 3 Tiers.

- **Tier 1** (~15 archivos nuevos, riesgo zero): subagents, hooks, slash commands, path-scoped rules, `.mcp.json`, `AGENTS.md`, `.gitignore`/worktree config, `docs/plans/` y `docs/gotchas.md`. Reversible con `git rm`.
- **Tier 2** (modificaciones a archivos existentes, justificadas, review por commit): fix de inexactitudes en `CLAUDE.md`, doc del gap multi-tenant, eliminar stale changelog, opcional pre-commit. _(Backend CI fue evaluado y luego revertido por decisión del usuario — ver §2.3.)_
- **Tier 3** (~2 refactors de código con regression test antes de cada uno): validator de SECRET_KEY en producción, test cross-user isolation.

**NO se va a tocar**: lógica de auth/refresh/blacklist, UI components, schemas existentes, migraciones committeadas, dependencias, skills existentes, `.env*`, `.gitmodules`.

**Estimado**: T1 ~30-45 min, T2 ~20 min, T3 ~30 min. Cada commit es atómico y verificable.

---

## Principios

1. NO reescribir código de aplicación funcional. Solo alinear config + docs + agregar guardrails.
2. NO romper tests existentes. Si pasa hoy, pasa después.
3. Cambios al código fuente SOLO si cierran un CRITICAL.
4. Multi-tenancy NO se implementa en este pase (es feature de producto). Solo se documenta el gap + test regresión cross-user.
5. Stack-aware: uv + npm + Alembic + REST + httpOnly cookies. Nada de pnpm/Drizzle/Stripe/server actions.
6. Submódulos: cambios al backend van como commits dentro de `backend/`, frontend dentro de `frontend/`, root como super-repo. Cada uno push-able a su remote.
7. Cada cambio reversible (commits atómicos + Conventional Commits).

---

# TIER 1 — Aditivos puros (zero riesgo)

Todo archivos nuevos. Reversibles con `git rm`. Aprobación: SI/NO global o por bullet específico.

## 1.1 Subagents (root, `.claude/agents/`)

5 subagents complementarios a los skills existentes (los skills siguen cubriendo CRUD; los subagents cubren review/security/exploración).

| Archivo | Modelo | Tools | Propósito |
|---|---|---|---|
| `.claude/agents/code-reviewer.md` | Sonnet | Read, Grep, Bash (read-only) | Revisa diff actual: repository pattern usage, docstring compliance, error handling consistency, type hints. **Awareness**: si detecta query sin filtro org_id (cuando exista Organization), flagear. |
| `.claude/agents/security-reviewer.md` | Opus | Read, Grep, Bash (read-only) — worktree | Audita: SECRET_KEY usage, JWT claims, password hashing solo en services, queries leak entre usuarios, env vars filtradas a logs, CORS wildcard. |
| `.claude/agents/test-writer.md` | Sonnet | Read, Edit, Write, Bash | Genera tests siguiendo `tests/conftest.py` patterns + factory-boy. Pytest fixtures correctos. |
| `.claude/agents/db-architect.md` | Sonnet | Read, Edit, Bash | Diseña schemas + migraciones. Enforce: `alembic revision --autogenerate`, NUNCA editar migración committeada, revisar SQL antes de commit. |
| `.claude/agents/codebase-explorer.md` | Haiku | Read, Grep, Glob, Bash | Lookups baratos para research multi-archivo. Reemplaza al `Explore` genérico cuando se quiere bajar costo. |

**Justificación**: hoy no hay ninguno. Los skills cubren generación pero no review/security/exploración eficiente.

## 1.2 Hooks (root, `.claude/hooks/`)

3 shell scripts + cableado en `.claude/settings.json`.

| Archivo | Evento | Bloquea |
|---|---|---|
| `.claude/hooks/protect-bash.sh` | `PreToolUse` matcher `Bash` | `rm -rf`, `git push --force`, `git reset --hard`, `git clean -fd`, comandos contra dominios prod (heurística por env var `PROD_HOST`). |
| `.claude/hooks/protect-files.sh` | `PreToolUse` matcher `Edit\|Write\|MultiEdit` | Edits a `**/.env`, `**/.env.*` (excepto `.example`), `backend/alembic/versions/*.py` (committeados), `**/package-lock.json`, `**/uv.lock`. Mensaje: "regenerate via tooling, no manual edit". |
| `.claude/hooks/scan-secrets.sh` | `UserPromptSubmit` | Regex sobre prompt del usuario buscando: AWS keys (`AKIA...`), JWTs (`eyJ...`), Stripe keys (`sk_live_`, `pk_live_`), Telegram tokens (formato `<digits>:<alnum>`), `BEGIN PRIVATE KEY`. Si detecta, bloquea con mensaje. |

**Cableado** (`.claude/settings.json`):
```jsonc
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/protect-bash.sh" }] },
      { "matcher": "Edit|Write|MultiEdit", "hooks": [{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/protect-files.sh" }] }
    ],
    "UserPromptSubmit": [
      { "hooks": [{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/scan-secrets.sh" }] }
    ]
  }
}
```

**Justificación**: hoy nada bloquea acciones destructivas. `settings.local.json` solo permite `Bash(find:*)` (overpermissive en otras direcciones).

## 1.3 Slash commands (root, `.claude/commands/`)

| Archivo | Comando | Acción |
|---|---|---|
| `.claude/commands/catchup.md` | `/catchup` | Resume últimos 20 commits + diff vs `master` + status. |
| `.claude/commands/ship.md` | `/ship` | Backend: `uv run ruff check && uv run mypy app && uv run pytest`. Frontend: `npm run lint && npm run build && npm test -- --run`. Si todo verde, abre draft PR via `gh pr create --draft`. |

## 1.4 Path-scoped rules (root, `.claude/rules/`)

Archivos referenciados desde `CLAUDE.md` root via `@`-syntax. No son auto-aplicados por Claude Code (no existe ese mecanismo nativo) — son docs cortas que el agent debe leer cuando opera en esos paths.

| Archivo | Aplica cuando se edita | Reglas |
|---|---|---|
| `.claude/rules/backend-data-layer.md` | `backend/app/repositories/**`, `backend/app/services/**` | Queries pasan por repository (no SQLAlchemy raw en endpoints). Cuando se introduzca `Organization`, todo `select(...)` filtra por `organization_id`. Reusar `BaseRepository`. Cross-user leak es bug de seguridad. |
| `.claude/rules/backend-migrations.md` | `backend/alembic/**` | Solo `alembic revision --autogenerate`. NUNCA editar migración committeada (crear una nueva). Revisar SQL generado antes de commit. Importar models en `alembic/env.py`. |
| `.claude/rules/frontend-api.md` | `frontend/src/api/**`, `frontend/src/features/**/api/**` | Types desde `src/types/generated/api.ts` (NO escribir tipos de API a mano). Regenerar con `npm run generate:types` después de cambios backend. Usar `apiClient` (no fetch directo). Errores via interceptor; no try/catch ad hoc. |

CLAUDE.md root va a ganar una sección "Path-scoped rules" con `@.claude/rules/...` refs.

## 1.5 MCP (root, `.mcp.json`)

```jsonc
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

**Nota**: el usuario ya tiene Context7 a nivel claude.ai (visible en MCP server instructions). Project-scoped `.mcp.json` se carga automáticamente para cualquier sesión en este repo, así que cualquier collaborator que clone el repo va a tener acceso. Si el usuario quiere skipear este punto (porque ya está global), removible. NO incluyo postgres/sentry/github porque requieren tokens y deps adicionales.

## 1.6 AGENTS.md (root, espejo tool-agnostic)

Archivo corto que apunta a `CLAUDE.md` para herramientas que no son Claude Code (Cursor, Aider, Codex CLI, etc.). Contenido: 1 párrafo + redirect a CLAUDE.md.

**Justificación**: convención de la industria 2026. Costo cero, beneficio: portabilidad.

## 1.7 Docs y gotchas (root, `docs/`)

- `docs/plans/` — directorio creado, este archivo dentro. Para futuros planes.
- `docs/gotchas.md` — template con secciones (Auth, Multi-tenancy gap, Migrations, Env vars, CORS, Submodules). Para llenar a medida que aparecen incidentes reales. Vacío al principio salvo el item ya conocido del multi-tenancy gap.

## 1.8 .gitignore + .worktreeinclude (root)

**`.gitignore`** — agregar líneas:
```
.claude/worktrees/
CLAUDE.local.md
**/CLAUDE.local.md
```

**`.worktreeinclude`** (NUEVO archivo en root):
```
.claude/
CLAUDE.md
docs/
```

**Justificación**: cuando se usen worktrees para sesiones paralelas, estos archivos deben venir con el branch.

## 1.9 Frontend `eslint-plugin-jsx-a11y`

Antes de commit voy a verificar si la dep ya está en `node_modules` (a veces viene transitively). Si SÍ → editar `frontend/.eslintrc.cjs` para sumar el plugin (Tier 1 directo). Si NO → mover esto a Tier 2 con tu OK explícito (requiere `npm i -D`).

## 1.10 Resumen Tier 1

| # | Archivo | Tipo |
|---|---|---|
| 1 | `.claude/agents/code-reviewer.md` | NEW |
| 2 | `.claude/agents/security-reviewer.md` | NEW |
| 3 | `.claude/agents/test-writer.md` | NEW |
| 4 | `.claude/agents/db-architect.md` | NEW |
| 5 | `.claude/agents/codebase-explorer.md` | NEW |
| 6 | `.claude/hooks/protect-bash.sh` | NEW (chmod +x) |
| 7 | `.claude/hooks/protect-files.sh` | NEW (chmod +x) |
| 8 | `.claude/hooks/scan-secrets.sh` | NEW (chmod +x) |
| 9 | `.claude/settings.json` | EDIT — solo agrega bloque `hooks` (T1 excepción: edit a archivo existente para wire de hooks recién creados; sin esto los hooks son inertes) |
| 10 | `.claude/commands/catchup.md` | NEW |
| 11 | `.claude/commands/ship.md` | NEW |
| 12 | `.claude/rules/backend-data-layer.md` | NEW |
| 13 | `.claude/rules/backend-migrations.md` | NEW |
| 14 | `.claude/rules/frontend-api.md` | NEW |
| 15 | `.mcp.json` | NEW |
| 16 | `AGENTS.md` | NEW |
| 17 | `docs/plans/` | DIR — ya existe con este archivo |
| 18 | `docs/gotchas.md` | NEW |
| 19 | `.gitignore` | EDIT — solo agrega 3 líneas |
| 20 | `.worktreeinclude` | NEW |
| 21 | `frontend/.eslintrc.cjs` | EDIT condicional (si dep disponible) |

**Commits propuestos** (Conventional, ordenados):
1. `chore(claude): add subagent definitions for review, security, tests, db, exploration`
2. `chore(claude): add bash, file, and secret protection hooks`
3. `chore(claude): wire protection hooks in settings.json`
4. `chore(claude): add /catchup and /ship slash commands`
5. `chore(claude): add path-scoped rules for data layer, migrations, frontend api`
6. `chore: add project-scoped mcp config with context7`
7. `chore: add AGENTS.md tool-agnostic mirror`
8. `docs: add plans dir and gotchas template`
9. `chore: ignore claude worktrees and local context overlays`
10. `chore: add worktreeinclude for parallel sessions`
11. `chore(frontend): enable jsx-a11y eslint plugin` (condicional)

---

# TIER 2 — Modificaciones a archivos existentes (review por commit)

## 2.1 `CLAUDE.md` (root) — fix de 3 inexactitudes (CRITICAL-3)

**Líneas a modificar**:
- 11, 14: actualizar/quitar line counts erróneos de submódulos.
- 62-67 ("Authentication Flow"): rewrite para reflejar httpOnly cookies + sin auto-refresh interceptor.
- 66 (file ref): `app/common/dependencies.py:get_current_user()` → `backend/app/api/deps.py:get_current_user (line 138)`.
- 71 (frontend permission): `<Can permission="USERS_READ">...</Can>` → `usePermissions()` hook (`frontend/src/hooks/use-permissions.ts`) + `<ProtectedRoute requiredPermissions={[...]}>` (`frontend/src/routes/protected-route.tsx`).
- Agregar al final de "Critical Gotchas" una sección **"Multi-tenancy: NOT IMPLEMENTED"** con 2 líneas: estado actual + ref a `docs/audits/claude-setup-audit-2026-04-25.md`.

**Commit**: `docs(claude): fix outdated auth and permission descriptions in root CLAUDE.md`

## 2.2 `backend/CLAUDE.md` — agregar sección multi-tenancy gap (CRITICAL-1 docs)

Sumar al final una sección corta "Multi-tenancy Status" con: estado (NOT IMPLEMENTED), evidencia (file:line del comentario fantasma en `user.py:74`), policy ("hasta que exista `Organization` model, todas las queries filtran por `owner_id`; cuando se introduzca, deben filtrar por `organization_id` o estar dentro del scope de un tenant"), link al audit.

**Commit**: `docs(backend): document multi-tenancy gap and policy`

## 2.3 ~~Backend CI workflow~~ — REVERTED

El workflow se agregó inicialmente y luego se removió por decisión del usuario ("no quiero CI en este repo"). Pre-commit (§2.4) queda como única gate automática local. HIGH-1 marcado como **skipped**.

Si se reactiva en el futuro: el workflow original (ruff format/check, mypy, pytest con servicios de Postgres + Mongo) está en git history.

## 2.4 `backend/.pre-commit-config.yaml` — opcional, requiere tu OK (HIGH-3)

Hook de ruff format + ruff check + (opcional) mypy. NO instala deps adicionales si ya hay `pre-commit` en uv (a verificar). Si hay que `uv add pre-commit`, va a esperar tu OK explícito.

**Commit**: `chore(backend): add pre-commit config for ruff and mypy`

## 2.5 `README.md` (root) — agregar pointer al audit

Una línea al inicio (o en sección Documentation): "Latest audit: `docs/audits/claude-setup-audit-2026-04-25.md`".

**Commit**: `docs: link latest claude setup audit from README`

## 2.6 `IMPLEMENTATION_SUMMARY.md` — borrar (decidido por usuario)

`git rm IMPLEMENTATION_SUMMARY.md`. La info queda en git history. Libera contexto inicial.

**Commit**: `chore: remove stale IMPLEMENTATION_SUMMARY (history in git)`

## 2.7 Resumen Tier 2

| # | Archivo | Tipo | Cierra |
|---|---|---|---|
| 1 | `CLAUDE.md` (root) | EDIT | CRITICAL-3 |
| 2 | `backend/CLAUDE.md` | EDIT | CRITICAL-1 (docs) |
| 3 | ~~`backend/.github/workflows/ci.yml`~~ | REVERTED | HIGH-1 marked skipped per user |
| 4 | `backend/.pre-commit-config.yaml` | NEW (opt-in) | HIGH-3 |
| 5 | `README.md` | EDIT | discoverability |
| 6 | `IMPLEMENTATION_SUMMARY.md` | DELETE | MED-5 |

---

# TIER 3 — Refactors de código (CRITICAL únicamente, regression test antes)

## 3.1 SECRET_KEY validator (CRITICAL-2)

**Paso A: Test que falla (antes del fix)**.

`backend/tests/unit/test_config.py` (o append si ya existe):
```python
"""Tests for application settings validation."""
import pytest

def test_dev_secret_key_rejected_in_production(monkeypatch):
    monkeypatch.setenv("ENVIRONMENT", "production")
    monkeypatch.setenv(
        "SECRET_KEY",
        "dev-secret-key-change-in-production-use-openssl-rand-hex-32",
    )
    # ... required vars omitted for brevity, fill in based on actual Settings ...
    from pydantic import ValidationError
    from app.core.config import Settings
    with pytest.raises(ValidationError):
        Settings()
```

**Verificación**: `uv run pytest tests/unit/test_config.py -v` → falla con un error que NO sea `ValidationError` (la validación todavía no existe).

**Commit (test red)**: `test(config): add failing test for prod SECRET_KEY default rejection`

**Paso B: Fix (validator)**.

`backend/app/core/config.py` — agregar Pydantic `field_validator`:
```python
from pydantic import field_validator

class Settings(BaseSettings):
    # ...
    SECRET_KEY: str
    ENVIRONMENT: str = "development"

    @field_validator("SECRET_KEY")
    @classmethod
    def reject_dev_secret_in_production(cls, v: str, info) -> str:
        env = info.data.get("ENVIRONMENT", "development")
        if env == "production" and v.startswith("dev-secret-key-"):
            raise ValueError(
                "SECRET_KEY must be set to a production-grade value when "
                "ENVIRONMENT=production. Generate with: openssl rand -hex 32"
            )
        return v
```

**Verificación**: `uv run pytest tests/unit/test_config.py -v` → pasa. `uv run mypy app` → pasa. `uv run pytest` (full suite) → sin regresiones.

**Commit (test green)**: `feat(security): reject dev SECRET_KEY in production environment`

## 3.2 Cross-user data isolation regression test (CRITICAL-1 prim)

**Test que falla si cambia el comportamiento**:

`backend/tests/integration/test_cross_user_leak.py`:
```python
"""Regression test: user A cannot read items owned by user B."""
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_user_cannot_read_other_users_item(
    client: AsyncClient,
    user_a_token: str,
    user_b_token: str,
    item_owned_by_user_b,
):
    """
    Closes CRITICAL-1 primitive (cross-user isolation).
    When Organization model exists, this should be widened to cross-tenant.
    """
    response = await client.get(
        f"/api/v1/items/{item_owned_by_user_b.id}",
        headers={"Authorization": f"Bearer {user_a_token}"},
    )
    assert response.status_code in (403, 404), (
        "user A leaked item of user B — multi-tenant isolation broken"
    )
```

**Fixtures necesarias**: `user_a_token`, `user_b_token`, `item_owned_by_user_b` en `tests/conftest.py`. Si no existen, agregarlas siguiendo factory-boy patterns ya usados.

**Verificación**: el test debe **pasar al primer intento** si la app actual ya enforces ownership en el endpoint (que debería). Si **falla**, encontramos un bug real → Tier 3.3 lo arreglamos. Probable resultado: test pasa, sirve como regresión guard.

**Commit**: `test(items): add cross-user data isolation regression test`

## 3.3 Resumen Tier 3

| # | Archivo | Tipo | Cierra |
|---|---|---|---|
| 1 | `backend/tests/unit/test_config.py` | NEW/APPEND (test red) | CRITICAL-2 (test) |
| 2 | `backend/app/core/config.py` | EDIT (validator) | CRITICAL-2 (fix) |
| 3 | `backend/tests/integration/test_cross_user_leak.py` | NEW | CRITICAL-1 (regression guard) |

---

# Lo que explícitamente NO se toca

- **Multi-tenancy real** (Organization model, JWT claims, frontend org switcher). Fuera de scope.
- **Lógica auth**: refresh rotation, blacklist, cookies, login. Funciona, IMPLEMENTATION_SUMMARY confirmó migración exitosa.
- **UI components**: shadcn/ui, layouts, features existentes.
- **Schemas Pydantic** y **tipos TS generados**.
- **Migraciones existentes** en `alembic/versions/`.
- **Skills existentes** (`fastapi-*`, `react-*`, orchestrators). Bien orientados al stack.
- **Cualquier dep nueva**: sin `npm i`, sin `uv add` salvo aprobación tier-por-tier.
- **`.env` reales** (solo `.env.example` se referencia; tampoco se modifica).
- **`.gitmodules`** y modelo de submódulos.
- **Code formatting**: Ruff/Prettier ya configurados.
- **Sentry / observability vendors** (no instalar sin pedido explícito).

---

# Orden de ejecución

1. **Tier 1** completo → push a remotes correspondientes (root super-repo). Verificación: `claude` arranca sin errores; `/context` muestra carga; subagent puede invocarse.
2. **Tier 2** uno por uno con review del diff por commit. Verificación: `cd backend && uv run ruff check app tests && uv run mypy app && uv run pytest`. Frontend igual si afecta.
3. **Tier 3** uno por uno con regression test antes (RED) y fix después (GREEN). Verificación: full pytest passes.

Cada tier tiene su propia aprobación. Podés decir "OK T1, esperá T2".

---

# Verificación post-aplicación (todos los tiers)

- [ ] `cd backend && uv run ruff check app tests` — verde
- [ ] `cd backend && uv run mypy app` — verde
- [ ] `cd backend && uv run pytest` — verde (sin nuevos failures)
- [ ] `cd frontend && npm run lint` — verde
- [ ] `cd frontend && npm run build` — verde
- [ ] `cd frontend && npm test -- --run` — verde
- [ ] `claude --version` arranca sin errores en hooks/settings
- [ ] `/context` lista CLAUDE.md root + rules cargando OK
- [ ] Hook `protect-bash.sh` bloquea un test manual `rm -rf /tmp/test-xyz`
- [ ] `Settings(SECRET_KEY="dev-secret-key-x", ENVIRONMENT="production")` raises `ValidationError`
- [ ] Test cross-user leak pasa
- [ ] `git log --oneline` muestra Conventional Commits

---

# Critical files

| Archivo | Tier | Rol |
|---|---|---|
| `.claude/settings.json` | T1 | Wire de hooks |
| `.claude/agents/*.md` (×5) | T1 | Subagents nuevos |
| `.claude/hooks/*.sh` (×3) | T1 | Guardrails ejecutables |
| `.claude/rules/*.md` (×3) | T1 | Path-scoped rules |
| `.mcp.json` | T1 | MCP project-scoped |
| `AGENTS.md`, `.gitignore`, `.worktreeinclude` | T1 | Convenciones |
| `CLAUDE.md` (root) | T2 | Fix CRITICAL-3 |
| `backend/CLAUDE.md` | T2 | Doc CRITICAL-1 |
| ~~`backend/.github/workflows/ci.yml`~~ | T2 reverted | — |
| `IMPLEMENTATION_SUMMARY.md` | T2 | Delete |
| `backend/app/core/config.py` | T3 | SECRET_KEY validator |
| `backend/tests/unit/test_config.py` | T3 | Regression CRITICAL-2 |
| `backend/tests/integration/test_cross_user_leak.py` | T3 | Regression CRITICAL-1 prim |

---

# Próxima acción

Espero tu OK por Tier. Formato sugerido:
- `OK T1` → arranco T1, hago los commits, te muestro `git log` al terminar.
- `OK T1 + T2` → arranco T1 y T2 secuencialmente.
- `OK todo` → ejecución completa con verificaciones intermedias.
- `Cambiá X en T2` → ajusto antes de ejecutar.
