# Plan: Claude files cleanup — 2026-04-28

**Audit fuente**: `docs/audits/claude-cleanup-audit-2026-04-28.md`
**Plan-mode artifact**: `/Users/julian/.claude/plans/eventual-brewing-sifakis.md` (espejo de este plan)
**Audits previos** (alignment, no cleanup): `claude-setup-audit-2026-04-25.md`, `claude-setup-audit-2026-04-25-followup.md`, `claude-setup-audit-2026-04-28.md`.

---

## Principios

- Eliminar es mejor que mantener "por si acaso" — los archivos huérfanos contaminan grep results y confunden a futuras sesiones de Claude.
- Cada eliminación atómica: el delete y la actualización de toda referencia entrante van en el MISMO commit.
- Si hay duda, NO eliminar — escalar a Tier 3 para decisión humana.
- Cambios a submódulos siguen la convención del repo: commit interno + bump del pointer en super-repo (`chore: bump <repo> submodule for X`).

---

## Tier 1 — Eliminaciones limpias (zero references, zero risk)

5 archivos `.skill` archive en `frontend/.claude/skills/`. Verificado: cero refs en `.md / .json / .sh / .yaml`. Mismo cleanup ya ejecutado en root via `4dae92f` (2026-04-25); falta propagar al submódulo frontend.

| # | Archivo | Bytes | Pareja folder | Refs |
|---|---|---|---|---|
| 1.1 | `frontend/.claude/skills/api-integration.skill` | 3037 | `api-integration/SKILL.md` | 0 |
| 1.2 | `frontend/.claude/skills/react-component.skill` | 2871 | `react-component/SKILL.md` | 0 |
| 1.3 | `frontend/.claude/skills/react-feature.skill` | 3776 | `react-feature/SKILL.md` | 0 |
| 1.4 | `frontend/.claude/skills/react-form.skill` | 3383 | `react-form/SKILL.md` | 0 |
| 1.5 | `frontend/.claude/skills/react-page.skill` | 3161 | `react-page/SKILL.md` | 0 |

**Plan de commits**:
- En `frontend/` (submódulo): `chore(claude): remove legacy .skill archive duplicates`. Body referencia precedente `4dae92f` y aclara que las 5 skills siguen registradas vía folder en root `settings.json`.
- En super-repo: `chore: bump frontend submodule for legacy .skill cleanup`.

**Verificación post-T1**:
```bash
find /Users/julian/Desktop/Personal/saas-boilerplate/frontend/.claude/skills -type f -name '*.skill'
# expect: empty

cat /Users/julian/Desktop/Personal/saas-boilerplate/.claude/settings.json | grep -A1 '"frontend/.claude/skills'
# expect: 5 folder paths registered (no .skill paths)
```

---

## Tier 2 — Consolidaciones / trims (low risk, doc-only)

Cuatro edits en `backend/CLAUDE.md` y `backend/docs/`. Cero cambios a código. Cada uno es un commit atómico en el submódulo backend.

### T2.1 — Trim Quick Start duplicado en backend FEATURE_WORKFLOW.md
- **Archivo**: `backend/docs/FEATURE_WORKFLOW.md` líneas 15–55.
- **Cambio**: reemplazar Quick Start / Prerequisites / Timeline por una línea "*See `docs/GETTING_STARTED.md` for setup; this guide covers the detailed implementation*".
- **Commit**: `docs(claude): trim duplicated quick-start in backend feature workflow`.

### T2.2 — Reemplazar "Database Strategy" genérica en backend/CLAUDE.md
- **Archivo**: `backend/CLAUDE.md` líneas 92–102.
- **Cambio**: bloque actual ("PostgreSQL for relational, MongoDB for unstructured, ejemplo Items → PostgreSQL") por una línea concisa apuntando a `docs/ARCHITECTURE.md` § Dual DB y al precedente real (`app/models/postgres/item.py`).
- **Commit**: `docs(claude): replace generic db-strategy block with link to root architecture`.

### T2.3 — Trim TOC y generic pytest troubleshooting en backend TESTING.md
- **Archivo**: `backend/docs/TESTING.md` líneas 1–18 y 694–755.
- **Cambio**: TOC de 18 líneas reemplazado por nada (markdown auto-rendering provee TOC visual); sección final "Troubleshooting / Slow Tests" eliminada — son tips genéricos de pytest accesibles en su doc oficial.
- **Commit**: `docs(claude): trim generic pytest sections from backend testing guide`.

### T2.4 — Reemplazar Pydantic gotcha genérica con ejemplo proyecto-específico
- **Archivo**: `backend/CLAUDE.md` línea 226.
- **Cambio**: "Forget `from_attributes = True` → Pydantic validation error" por una referencia al patrón real de schemas (`from_attributes=True` en `app/schemas/user.py`, `item.py` con `model_config = ConfigDict(from_attributes=True)`).
- **Commit**: `docs(claude): replace generic pydantic gotcha with project-specific schema example`.

**Bump al final del Tier**: `chore: bump backend submodule for doc consolidation pass` en super-repo (un solo bump al final del Tier para reducir noise en el log).

**Verificación post-T2**:
- Releer cada doc trimeado end-to-end para confirmar cero cross-refs internos rotos al rango eliminado.
- `grep -rn "FEATURE_WORKFLOW.md:15\|FEATURE_WORKFLOW.md:30\|FEATURE_WORKFLOW.md:55"` — confirm 0 matches (nadie pinneó esas líneas).

---

## Tier 3 — Decisiones que requieren tu input

Cada item con opciones explícitas. NO se ejecuta nada sin instrucción específica.

### T3.A — `docs/prompts/EXAMPLE_USAGE.md` (747L) y `docs/prompts/custom-instructions.md` (215L)

Ambos verificados como 0 refs en cualquier `.md / .json / .sh` del repo. Describen un workflow Claude.ai Project superseded por `.claude/skills/` + CLAUDE.md.

| Opción | Descripción | Recomendación |
|---|---|---|
| A1 | Eliminar ambos. ~960 líneas de docs no referenciados. | ⭐ Mi voto. Si los necesitás como template, los recuperás de git history. |
| A2 | Mantener ambos. Inertes (cero blast radius), podrían servir de template futuro. | — |
| A3 | Consolidar contenido único de `custom-instructions.md` en `docs/CLAUDE_CODE_BEST_PRACTICES.md` y borrar; borrar `EXAMPLE_USAGE.md` directo. | — |

### T3.B — `backend/docs/prompts/backend-patterns.md` (416L)

8 referencias activas. NO es huérfano — el initial guess fue incorrecto (corregido en el audit). Content overlap con `backend/CLAUDE.md` + `.claude/rules/backend-data-layer.md` es real, pero la consolidación implica:
1. Mover contenido único a CLAUDE.md y rules (~30 min de merge).
2. Reescribir las 8 referencias entrantes.
3. Borrar el archivo.

| Opción | Descripción | Recomendación |
|---|---|---|
| B1 | Skip en este pase. Documentar como deuda en `docs/gotchas.md`. Re-evaluar cuando se necesite tocar la sección por otra razón. | ⭐ Mi voto. La consolidación bien hecha es un proyecto de su propio sprint. |
| B2 | Hacer la consolidación ahora como un commit atómico grande. | — |

### T3.C — `docs/SKILLS_REFERENCE.md` (913L)

Mirror narrativo de `.claude/settings.json`. Doble fuente de verdad cuando se modifica un skill.

| Opción | Descripción | Recomendación |
|---|---|---|
| C1 | Mantener como referencia humana (prosa vs schema). | — |
| C2 | Trim agresivo: un párrafo por skill + link a `<name>/SKILL.md`. ~150 líneas finales. | ⭐ Mi voto. Conserva valor humano, reduce drift. |
| C3 | Eliminar y actualizar README + settings.json refs. | — |

### T3.D — Root `README.md` (559L)

Pre-existing flag (NEW-MED-4 del 2026-04-28). Out of scope salvo solicitud explícita. **Default**: no tocar.

---

## Lo que NO se toca

- Application code (`backend/app/`, `frontend/src/`).
- Tests, migraciones, `.env*`, secretos.
- `README.md` de root, backend o frontend.
- `docs/audits/` y `docs/plans/` — historial.
- `settings.local.json` — local del dev.
- `.gitignore`, `.gitmodules`, `.worktreeinclude`, `.mcp.json`, `AGENTS.md`.
- Todo el contenido bajo `.claude/{agents,commands,hooks,rules,skills}/` en cualquier scope (verificado limpio post-2026-04-28).
- `frontend/CLAUDE.md` (verificado clean).
- Sections proyecto-específicas de `backend/CLAUDE.md` (7-step workflow, RBAC, multi-tenancy gap, request-id, rate limit, alembic env.py rule).

---

## Orden de ejecución

1. ✅ Mirror Phase 1 a `docs/audits/claude-cleanup-audit-2026-04-28.md` + Phase 2 a este archivo (commit en super-repo).
2. **Tier 1**: 1 commit en submodule frontend (5 deletes) + 1 bump en super-repo.
3. (Wait for OK) **Tier 2**: 4 commits en submodule backend + 1 bump al final.
4. (Wait per-option) **Tier 3**: solo lo aprobado opción-por-opción.

Cada tier termina con `git log --oneline` de los nuevos commits y espera OK explícito antes del siguiente.

---

## Verificación universal post-cualquier-tier

```bash
# Cero refs rotos
grep -rn "<deleted-basename>" /Users/julian/Desktop/Personal/saas-boilerplate \
  --include='*.md' --include='*.json' --include='*.sh' --include='*.yaml' \
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.venv

# Estado limpio del working tree
git status

# Suite + lint sin regression (si afecta el submódulo backend)
cd backend && uv run ruff check app tests && uv run pytest tests/unit -q --no-cov
```
