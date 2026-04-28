# Plan: Alineación Claude Code 2026-04-28

**Audit fuente**: `docs/audits/claude-setup-audit-2026-04-28.md`
**Audits anteriores**:
- `docs/audits/claude-setup-audit-2026-04-25.md` (cerrado)
- `docs/audits/claude-setup-audit-2026-04-25-followup.md` (cerrado)
**Plan anterior**: `docs/plans/claude-setup-alignment-followup.md` (ejecutado)

---

## Resumen ejecutivo

4 hallazgos accionables, todos detectados HOY: 3 🔴 CRITICAL + 1 🟡 HIGH. Ninguno requiere reescribir lógica de negocio. El más invasivo es 1 línea de código en `backend/alembic/env.py`. El resto son edits a archivos de config / docs.

**NO se reabren** los items skipped en pasadas anteriores: CI backend, E2E Playwright, Sentry/observability.

**Submódulos**: 2 de los 4 fixes viven en `backend/` (submódulo). Eso implica commit interno + bump del pointer en el super-repo (siguiendo la convention `chore: bump backend submodule for ...` documentada en `CLAUDE.md`).

---

## Principios de este plan

- NO reescribir código de aplicación funcional. Solo cerrar drift detectado.
- NO romper tests existentes. Si pasa antes, pasa después.
- Cambios de código solo si cierran un gap CRITICAL (NEW-CRIT-A).
- Cada cambio justificado con referencia a finding del audit.
- Commits atómicos Conventional. Reversibles uno por uno.

---

## Tier 1 — Cleanup AI config (aditivos puros, zero riesgo)

Archivos en el super-repo (`.claude/` raíz). Sin tocar submódulos.

### T1.1 — Fix drift `init_postgres` en rule de migraciones (cierra NEW-CRIT-B)

**Archivo**: `.claude/rules/backend-migrations.md` (líneas 17-21).

**Cambio**: reemplazar la sección "Initial-schema drift note" por una nota de status actual.

**Diff conceptual**:
```diff
-## Initial-schema drift note
-
-`init_postgres()` in `backend/app/main.py:106-107` currently creates initial schema directly in dev. This bypasses Alembic and risks drift in prod. New tables MUST also have a corresponding Alembic migration so prod gets them.
+## Schema ownership
+
+Alembic is the single source of truth for the PostgreSQL schema in **all** environments (dev/staging/prod). `init_postgres()` was removed during the 2026-04-25 alignment work — the empty-schema bootstrap path that bypassed migrations no longer exists. Every new model needs its corresponding migration. If you ever see direct `Base.metadata.create_all()` reintroduced for app schema, it's a regression.
```

**Justificación**: el audit del 25/04 cerró esta misma drift en `.claude/agents/db-architect.md` (commit `6d63b89`) pero la rule path-scoped quedó abierta. Hoy una sesión que edite migraciones lee esta rule y le inyecta info falsa al modelo.

**Commit propuesto**: `chore(claude): drop obsolete init_postgres drift note from migrations rule`.

**Verificación**:
- `grep -n "init_postgres" .claude/rules/backend-migrations.md` → debería volver vacío (excepto referencia histórica si la dejamos).

---

### T1.2 — Ampliar `scan-secrets.sh` con patrones Anthropic + OpenAI (cierra NEW-HIGH-A)

**Archivo**: `.claude/hooks/scan-secrets.sh`.

**Cambio**: agregar 2 chequeos nuevos junto a los existentes (Stripe, AWS, JWT, Telegram, PEM, GitHub, Slack).

**Diff conceptual**:
```bash
# Anthropic API key (sk-ant-api03-..., sk-ant-oat01-...)
if grep -qE 'sk-ant-(api|oat)[0-9]{2}-[A-Za-z0-9_-]{32,}' "$INPUT_FILE"; then
  echo "BLOCKED: Anthropic API key detected in prompt" >&2
  exit 2
fi

# OpenAI API key (modern sk-proj-..., classic sk-...)
# Length floor 32 to reduce false positives on partial strings.
if grep -qE 'sk-(proj-)?[A-Za-z0-9_-]{40,}' "$INPUT_FILE"; then
  echo "BLOCKED: OpenAI API key detected in prompt" >&2
  exit 2
fi
```

**Justificación**: este es un boilerplate orientado a Claude Code. La probabilidad de que un developer pegue un curl de ejemplo de docs de Anthropic/OpenAI en un prompt es alta. Hoy el hook deja pasar esas keys → riesgo de exfil si el transcript se comparte.

**Validación pre-commit**:
1. Ejecutar `.claude/hooks/scan-secrets.sh` con un input que contenga `sk-ant-api03-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` → debe bloquear.
2. Ejecutar con un input que contenga `sk-proj-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` → debe bloquear.
3. Ejecutar con un input limpio (ej. `hola mundo`) → debe pasar (`exit 0`).
4. Verificar que no rompe los chequeos existentes con regression cases (si hay test fixtures; si no, smoke con un AKIA key debe seguir bloqueando).

**Commit propuesto**: `feat(security): scan Anthropic and OpenAI keys in claude prompts`.

---

### Tier 1 — verificación final

- [ ] `bash .claude/hooks/scan-secrets.sh` corre sin errores de sintaxis (smoke).
- [ ] `grep -rn "init_postgres" .claude/` → solo referencias históricas (ej. en docs/audits), nada en rules/agents.
- [ ] `git log --oneline` muestra 2 commits Conventional.

---

## Tier 2 — Edits puntuales a `backend/CLAUDE.md` (submódulo)

### T2.1 — Fix import path en endpoint snippet (cierra NEW-CRIT-C)

**Archivo**: `backend/CLAUDE.md`, paso 6 del "7-Step Workflow".

**Cambio**: el snippet actualmente muestra:
```python
from app.common.dependencies import get_db, get_current_user
```

Debe ser (verificando los paths reales en el repo antes de editar):
```python
from app.api.deps import get_current_user
from app.db.postgres import get_db   # confirmar ubicación exacta
```

**Por qué necesita verificación**: el audit confirma `app.api.deps.get_current_user` (line 138 según audit del 25/04). El path de `get_db` debe verificarse en el código real (probablemente `app/db/postgres.py` o `app/api/deps.py` también) antes de escribir la línea final.

**Otros possibly stale refs en backend/CLAUDE.md** (a verificar oportunísticamente, sin scope creep):
- "Common Errors → Security": *"401 errors → verify `Authorization: Bearer <token>`"* — opcionalmente expandir para mencionar httpOnly cookies como camino primario (NEW-MED-A del audit). **NO incluir en este tier** salvo que sea trivial; es polish, no drift.
- Cualquier otra mención de `app.common.dependencies` en el archivo (búsqueda completa).

**Workflow** (submódulo):
```bash
cd backend
# editar CLAUDE.md
git checkout -b fix/claude-md-endpoint-import   # si la rama no existe
git add CLAUDE.md
git commit -m "docs(claude): fix stale import path in endpoint workflow snippet"
# push & merge a master del submódulo (o dejar la rama y bumpear el pointer al SHA exacto si el usuario prefiere no mergear todavía)
cd ..
git add backend
git commit -m "chore: bump backend submodule for endpoint snippet import fix"
```

**⚠️ Punto a confirmar antes de ejecutar**: ¿mergeamos la fix al `master` del submódulo backend, o trabajamos en una rama del submódulo y bumpeamos al SHA de la rama? Política previa observada en commits (`d3ca776`, `419f1c5`, etc.): se hicieron varios bumps de backend, sugiere que se mergeó a master del submódulo. **Asumiré ese flujo salvo otra indicación**.

**Verificación post-fix**:
- `grep -n "app.common.dependencies" backend/CLAUDE.md` → vacío.
- `grep -n "from app.api.deps" backend/CLAUDE.md` → al menos 1 match en el snippet.

**Commits propuestos** (2 commits, uno por repo):
1. En `backend/`: `docs(claude): fix stale import path in endpoint workflow snippet`.
2. En super-repo: `chore: bump backend submodule for endpoint snippet import fix`.

---

## Tier 3 — Refactor de código (1 línea + opcional test)

### T3.1 — `backend/alembic/env.py`: importar `refresh_token_blacklist` (cierra NEW-CRIT-A)

**Archivo**: `backend/alembic/env.py:33`.

**Cambio**:
```diff
-from app.models.postgres import user, item  # noqa: F401
+from app.models.postgres import user, item, refresh_token_blacklist  # noqa: F401
```

**Por qué es CRITICAL pese a ser 1 línea**: la próxima vez que alguien (humano o Claude) modifique `RefreshTokenBlacklist`, `alembic revision --autogenerate` va a generar una migración VACÍA sin aviso visible. El cambio sale a prod sin migración. Es exactamente el tipo de bug silencioso que el repo intentó cerrar removiendo `init_postgres`.

**Test de regresión opcional** (T3.1.b): un test unitario que verifique que `Base.metadata.tables` (post-import-side-effects en `env.py`) contiene **todas** las tablas declaradas en `app/models/postgres/__init__.py`. Si alguien agrega un modelo y olvida importarlo en env.py, el test rompe.

Skeleton:
```python
# backend/tests/unit/test_alembic_env_imports.py
"""Regression test: alembic/env.py must import every postgres model.

Prevents the silent autogenerate failure mode where a new table is added but
not registered in env.py, leaving the schema undetectable by Alembic.
"""

import importlib
import pkgutil

import app.models.postgres
from app.db.postgres import Base


def test_alembic_env_registers_all_postgres_models():
    """Every model module in app.models.postgres must be importable from env.py side-effects."""
    # Force-import every submodule to populate Base.metadata
    for _, modname, _ in pkgutil.iter_modules(app.models.postgres.__path__):
        importlib.import_module(f"app.models.postgres.{modname}")
    expected_table_names = {t.name for t in Base.metadata.tables.values()}

    # Import env.py-style: only the lines from the file
    # Then verify env.py's import set covers expected_table_names.
    # (Exact assertion form depends on conventions; treat this as a sketch.)
    assert "refresh_token_blacklist" in expected_table_names
    assert "users" in expected_table_names
    assert "items" in expected_table_names
```

**Decisión**: incluir T3.1.b (test) **opcional** — si el usuario lo rechaza, T3.1 sin test sigue siendo válido (el bug se cierra de todas formas, pero queda sin regresión-net).

**Workflow** (submódulo backend):
```bash
cd backend
# editar alembic/env.py
git add alembic/env.py
# (si T3.1.b aprobado: git add tests/unit/test_alembic_env_imports.py)
uv run pytest tests/ -x       # smoke
git commit -m "fix(alembic): register refresh_token_blacklist in env.py"
cd ..
git add backend
git commit -m "chore: bump backend submodule for alembic env.py import fix"
```

**Commits propuestos**:
1. En `backend/`: `fix(alembic): register refresh_token_blacklist in env.py` (+ opcional test).
2. En super-repo: `chore: bump backend submodule for alembic env.py import fix`.

---

## Lo que explícitamente NO se toca

- Lógica de auth (refresh, blacklist, JWT rotation).
- Schemas Pydantic, modelos SQLAlchemy existentes.
- Migraciones existentes en `alembic/versions/` (NUNCA editar committed migrations).
- Skills (`fastapi-*`, `react-*`, orchestrators) — todas verificadas accurate.
- `<Can>` component / sidebar — patrón canónico, ya alineado.
- `frontend/CLAUDE.md` — verificado clean.
- Multi-tenancy / Organization model — fuera de scope (decisión vigente).
- README.md root largo (NEW-MED-B) — pre-existing, no urgente.
- Frontend test coverage (NEW-MED-C) — pre-existing.
- `audit-claude-setup.md` en español — intencional.
- Sentry, Playwright, backend CI — skipped por decisión.

---

## Orden de ejecución recomendado

1. **Tier 1** completo (super-repo, 2 commits).
2. **Tier 2** (submódulo backend + bump, 2 commits).
3. **Tier 3** (submódulo backend + bump, 2 commits — opcional test agrega 1 más).

Cada tier independiente: el usuario puede aprobar Tier 1 y rechazar Tier 2/3, o cualquier combinación.

---

## Verificación post-aplicación (al cerrar Tier 3)

Super-repo:
- [ ] `grep -rn "init_postgres" .claude/` → vacío en rules/agents.
- [ ] `grep -rn "app.common.dependencies" backend/CLAUDE.md` → vacío.
- [ ] `bash .claude/hooks/scan-secrets.sh < <(echo "sk-ant-api03-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")` → exit 2.
- [ ] `git log --oneline | head -10` → Conventional Commits.

Backend submódulo:
- [ ] `grep -n "refresh_token_blacklist" backend/alembic/env.py` → match en línea 33.
- [ ] `cd backend && uv run pytest tests/ -x` → verde.
- [ ] `cd backend && uv run ruff check app tests` → verde.
- [ ] (Si T3.1.b aprobado) `cd backend && uv run pytest tests/unit/test_alembic_env_imports.py -v` → verde.

---

## Critical files

| Archivo | Tier | Tipo | Rol |
|---|---|---|---|
| `docs/audits/claude-setup-audit-2026-04-28.md` | T1 NEW (ya creado) | NEW | Audit deliverable |
| `docs/plans/claude-setup-alignment-2026-04-28.md` | T1 NEW (este archivo) | NEW | Plan |
| `.claude/rules/backend-migrations.md` | T1 EDIT | EDIT | Drop init_postgres drift |
| `.claude/hooks/scan-secrets.sh` | T1 EDIT | EDIT | Anthropic/OpenAI patterns |
| `backend/CLAUDE.md` | T2 EDIT (submódulo) | EDIT | Endpoint snippet import |
| `backend/alembic/env.py` | T3 EDIT (submódulo) | EDIT | Import refresh_token_blacklist |
| `backend/tests/unit/test_alembic_env_imports.py` | T3.1.b OPCIONAL (submódulo) | NEW | Regression test |

---

## Próxima acción

Esperar approval **tier-por-tier**. Sugiero arrancar por Tier 1 (zero risk, super-repo only).
