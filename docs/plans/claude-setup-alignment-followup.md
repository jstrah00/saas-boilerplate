# Plan: Alignment Follow-up 2026-04-25

**Audit fuente**: `docs/audits/claude-setup-audit-2026-04-25-followup.md`
**Audit anterior**: `docs/audits/claude-setup-audit-2026-04-25.md`
**Plan anterior**: `docs/plans/claude-setup-alignment.md`

---

## Resumen ejecutivo

3 hallazgos accionables en este follow-up: 1 🔴 CRITICAL (drift `<Can>` doc-vs-code), 3 🟡 HIGH (settings.json paths, CLAUDE.md skill count, types generados), 1 🟢 MED (db-architect drift note). Todo se cierra con edits puntuales en archivos AI-config + cleanup ya ejecutado.

NO se reabren los items skipped del plan anterior (CI backend, Playwright, Sentry).

---

## Tier 1 — Cleanup trivial (zero riesgo)

### ✅ T1.1 — Borrar `.skill` zips duplicados

**Status**: ejecutado. Commit `4dae92f chore(claude): remove duplicate .skill zip artifacts`.

### ✅ T1.2 — Audit follow-up file

**Status**: este pase produce `docs/audits/claude-setup-audit-2026-04-25-followup.md`.

### ✅ T1.3 — Plan follow-up file

**Status**: este archivo.

---

## Tier 2 — Edits puntuales a archivos existentes

### T2.1 — Reconciliar `<Can>` drift (cierra NEW-CRITICAL-1)

**Decisión**: preservar `<Can>` como patrón canónico (Opción B del audit). Alinear docs.

**Edits**:

1. `CLAUDE.md` (root) — sección "Permission System" (línea 73): mencionar `<Can>` como gate JSX canónico junto con `usePermissions()` hook y `<ProtectedRoute>`.

2. `.claude/agents/code-reviewer.md:26`: invertir la regla — *"`<Can>` (`src/components/can.tsx`) is the canonical JSX permission gate. Hand-rolled `if(hasPermission(...))` patterns where `<Can>` would fit are inconsistent — flag them."*.

3. `.claude/rules/frontend-api.md`: agregar fila documentando `<Can perform={Permission.X}>` como permission gate JSX preferido para mostrar/ocultar elementos en componentes.

4. (Opcional) `frontend/CLAUDE.md`: si describe el sistema de permisos, asegurar consistencia. **Verificar primero**.

**Commit propuesto**: `docs(claude): document <Can> as canonical permission gate across docs and agents`.

### T2.2 — Fix CLAUDE.md skill count (cierra NEW-HIGH-2)

**Edit**: `CLAUDE.md:26` — actualizar a 6 backend skills incluyendo `feature-from-plan`.

**Commit propuesto**: `docs(claude): correct backend skill count to include feature-from-plan`.

### T2.3 — Fix paths stale en settings.json (cierra NEW-HIGH-1)

**Edits** en `.claude/settings.json` (líneas 232-238):

- `backend_example`: `backend/app/api/v1/endpoints/users.py` → `backend/app/api/v1/users.py`.
- `model_example`: `backend/app/models/user.py` → `backend/app/models/postgres/user.py`.
- `form_example`: `frontend/src/features/auth/components/LoginForm.tsx` → `frontend/src/features/auth/components/login-form.tsx`.

**Commit propuesto**: `chore(claude): fix stale file references in settings.json examples`.

### T2.4 — Drop init_postgres drift note del db-architect (cierra NEW-MED-2)

**Edit**: `.claude/agents/db-architect.md:32-34` — reemplazar la "Drift note" por: *"Alembic es owner único del schema en todos los environments. Cualquier modelo nuevo necesita su migración correspondiente; `init_postgres()` ya no existe."*

**Commit propuesto**: `chore(claude): drop obsolete init_postgres drift note from db-architect`.

### T2.5 — Documentar `npm run generate:types` en GETTING_STARTED (cierra NEW-HIGH-3)

**Edit**: `docs/GETTING_STARTED.md` — agregar paso obligatorio post-clone: con backend corriendo, `cd frontend && npm run generate:types` para crear `src/types/generated/api.ts`. **Sin esto el TS compile falla**.

**Por qué no committear el archivo generado**: es derivado del OpenAPI live; commitearlo introduce drift. Mejor hacerlo step explícito en setup.

**Commit propuesto**: `docs(getting-started): document mandatory type generation step post-clone`.

---

## Tier 3 — Refactors de código

**Vacío en este pase**. Todos los CRITICAL de código ya están cerrados por la pasada anterior (SECRET_KEY validator, init_postgres remoción, cross-user leak tests). NEW-CRITICAL-1 se cierra documentalmente, no requiere cambio de código.

**Opcional MED-1** (no en este pase, requiere pedido explícito): test que demuestre que `/api/v1/users` requiere `USERS_READ` permission.

---

## Lo que explícitamente NO se toca

- Lógica de auth/refresh/blacklist.
- UI components, schemas Pydantic, tipos TS generados.
- Migraciones existentes en `alembic/versions/`.
- Skills existentes (`fastapi-*`, `react-*`, orchestrators).
- Cualquier dep nueva (sin `npm i`, sin `uv add`).
- `<Can>` component file ni el sidebar (decidimos preservarlo).
- Sentry, Playwright, backend CI (mantener skipped).

---

## Verificación post-aplicación

- [ ] `cd backend && uv run ruff check app tests` — verde
- [ ] `cd backend && uv run mypy app` — verde (si pre-existente)
- [ ] `cd backend && uv run pytest` — verde
- [ ] `cd frontend && npm run lint` — verde
- [ ] `grep -n "no .Can. component\|There is no \`<Can>\`" CLAUDE.md .claude/agents/*.md` — sin matches (drift cerrado)
- [ ] `ls backend/app/api/v1/users.py backend/app/models/postgres/user.py frontend/src/features/auth/components/login-form.tsx` — todos existen
- [ ] `ls .claude/skills/*.skill 2>/dev/null` — vacío
- [ ] `grep -n "feature-from-plan" CLAUDE.md` — match en línea 26
- [ ] `grep -n "init_postgres" .claude/agents/db-architect.md` — solo aparece en contexto histórico, no como instrucción activa
- [ ] `git log --oneline | head -10` — Conventional Commits

---

## Critical files

| Archivo | Tier | Rol |
|---|---|---|
| `docs/audits/claude-setup-audit-2026-04-25-followup.md` | T1 NEW | Audit deliverable |
| `docs/plans/claude-setup-alignment-followup.md` | T1 NEW | Este archivo |
| `CLAUDE.md` | T2 EDIT | Skill count + Can mention |
| `.claude/agents/code-reviewer.md` | T2 EDIT | Reconciliar `<Can>` |
| `.claude/agents/db-architect.md` | T2 EDIT | Drop init_postgres drift |
| `.claude/settings.json` | T2 EDIT | 3 paths stale |
| `.claude/rules/frontend-api.md` | T2 EDIT | Sumar fila `<Can>` |
| `docs/GETTING_STARTED.md` | T2 EDIT | Doc generate:types |

---

## Próxima acción

Aplicar Tier 2 con commits atómicos Conventional. Cada cambio verificable independientemente.
