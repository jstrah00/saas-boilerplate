# Claude Files Cleanup Audit — 2026-04-28

**Repo**: `saas-boilerplate` (monorepo con submódulos)
**Branch**: `chore/claude-alignment-2026-04-25`
**Auditor**: Claude (Opus 4.7) read-only audit con 3 exploradores en paralelo (root, backend submodule, frontend submodule) + verificación directa de findings.
**Audits anteriores** (alignment, no cleanup):
- `docs/audits/claude-setup-audit-2026-04-25.md`
- `docs/audits/claude-setup-audit-2026-04-25-followup.md`
- `docs/audits/claude-setup-audit-2026-04-28.md`

Este audit ataca un eje distinto: **redundancia, legacy, y orfandad** en archivos de configuración Claude Code, no alignment con código.

---

## 1. Resumen

- Total de archivos Claude-related identificados: ~50 (cubriendo `.claude/`, CLAUDE.md ×3, AGENTS.md, .mcp.json, docs/, prompts/, audits/, plans/, skills folder-format, skills `.skill` archives).
- **Candidatos a eliminar limpiamente**: 5 (`.skill` archives en frontend submodule).
- **Candidatos a eliminar pendiente decisión humana**: 2 (prompts huérfanos en root).
- **Candidatos a consolidar/trimear**: 4 (secciones genéricas en `backend/CLAUDE.md` + `backend/docs/`).
- **Archivos con referencias rotas**: 0.
- **Drift NUEVO desde el audit del 2026-04-28**: ninguno; este es un eje complementario.

---

## 2. Inventario por scope

### 2.1 Root `.claude/`

| Archivo | Líneas | Estado | Razón / referencias |
|---|---|---|---|
| `.claude/settings.json` | 290 | ✅ ÚNICO | Auto-loaded; permissions + hooks + skills metadata |
| `.claude/settings.local.json` | 12 | ✅ ÚNICO | Local override (no committeado en escenarios típicos) |
| `.claude/agents/code-reviewer.md` | 39 | ✅ ÚNICO | Auto-discovered |
| `.claude/agents/codebase-explorer.md` | ~50 | ✅ ÚNICO | Auto-discovered |
| `.claude/agents/db-architect.md` | ~60 | ✅ ÚNICO | Auto-discovered |
| `.claude/agents/security-reviewer.md` | ~50 | ✅ ÚNICO | Auto-discovered |
| `.claude/agents/test-writer.md` | ~50 | ✅ ÚNICO | Auto-discovered |
| `.claude/commands/audit-claude-setup.md` | ~220 | ✅ ÚNICO | Auto-discovered (intencionalmente en español) |
| `.claude/commands/catchup.md` | ~30 | ✅ ÚNICO | Auto-discovered (`/catchup`) |
| `.claude/commands/ship.md` | ~40 | ✅ ÚNICO | Auto-discovered (`/ship`) |
| `.claude/hooks/protect-files.sh` | 26 | ✅ ÚNICO | Wired en settings.json |
| `.claude/hooks/scan-secrets.sh` | 29 | ✅ ÚNICO | Wired en settings.json |
| `.claude/rules/backend-data-layer.md` | ~30 | ✅ ÚNICO | Path-scoped via `@`-ref desde CLAUDE.md |
| `.claude/rules/backend-migrations.md` | 22 | ✅ ÚNICO | Path-scoped |
| `.claude/rules/frontend-api.md` | 37 | ✅ ÚNICO | Path-scoped |
| `.claude/skills/api-to-ui/SKILL.md` | 1188 | ✅ ÚNICO | Cross-stack orchestrator |
| `.claude/skills/backend-first/SKILL.md` | 1123 | ✅ ÚNICO | Cross-stack orchestrator |
| `.claude/skills/fullstack-feature/SKILL.md` | 1427 | ✅ ÚNICO | Cross-stack orchestrator |

**Subtotal**: 18 archivos, todos necesarios. **Cero acción**.

### 2.2 Root `docs/`

| Archivo | Líneas | Estado | Notas |
|---|---|---|---|
| `CLAUDE.md` (root) | 196 | ✅ ÚNICO | Orchestration, lean. Sin overlap con backend/frontend. |
| `AGENTS.md` | 16 | ✅ ÚNICO | Pointer tool-agnóstico. |
| `.mcp.json` | 8 | ✅ ÚNICO | Context7. |
| `README.md` | 559 | ✅ ÚNICO (largo, pre-existing flag) | NEW-MED-4 del audit anterior; no se toca acá. |
| `docs/CLAUDE_CODE_BEST_PRACTICES.md` | 842 | ✅ ÚNICO | Guide profundo (Plan mode, model selection, debugging). Complementa CLAUDE.md sin duplicar. |
| `docs/SKILLS_REFERENCE.md` | 913 | ❓ DUDOSO | Mirror narrativo de `settings.json`. **Tier 3.C**. |
| `docs/FULLSTACK_WORKFLOW.md` | 706 | ✅ ÚNICO | E2E workflows con detalle. |
| `docs/PERMISSIONS.md` | 791 | ✅ ÚNICO | RBAC reference completa. |
| `docs/TROUBLESHOOTING.md` | 994 | ✅ ÚNICO | Diagnostics operacional. |
| `docs/ARCHITECTURE.md` | 615 | ✅ ÚNICO | Tech stack + dual DB + auth flow. |
| `docs/GETTING_STARTED.md` | 439 | ✅ ÚNICO | Onboarding. |
| `docs/gotchas.md` | 35 | ✅ ÚNICO | Living log. |
| `docs/prompts/CLAUDE_PROJECT_SETUP.md` | 792 | ✅ ÚNICO | Template Claude.ai Project (referenciado). |
| `docs/prompts/integration-patterns.md` | 1365 | ✅ ÚNICO | Code patterns referenciado desde CLAUDE.md. |
| `docs/prompts/EXAMPLE_USAGE.md` | 747 | 🗑️ HUÉRFANO | **0 referencias** verificadas. Tier 3.A. |
| `docs/prompts/custom-instructions.md` | 215 | 🗑️ HUÉRFANO | **0 referencias** verificadas. Tier 3.A. |

**Subtotal**: 16 archivos. 2 huérfanos confirmados pendientes de decisión.

### 2.3 backend submodule

| Archivo | Líneas | Estado | Notas |
|---|---|---|---|
| `backend/CLAUDE.md` | 281 | ⚠️ MIXTO | ~80% único; **secciones 92-102 (Database Strategy)** y **línea 226 (Pydantic gotcha)** son genéricas. Tier 2.2 + 2.4. |
| `backend/.claude/skills/fastapi-endpoint/SKILL.md` | 593 | ✅ ÚNICO | Folder format. |
| `backend/.claude/skills/fastapi-migration/SKILL.md` | 328 | ✅ ÚNICO | Folder format. |
| `backend/.claude/skills/fastapi-model/SKILL.md` | 464 | ✅ ÚNICO | Folder format. |
| `backend/.claude/skills/fastapi-permission/SKILL.md` | 407 | ✅ ÚNICO | Folder format. |
| `backend/.claude/skills/fastapi-test/SKILL.md` | 580 | ✅ ÚNICO | Folder format. |
| `backend/.claude/skills/feature-from-plan/SKILL.md` | 380 | ✅ ÚNICO | Folder format. |
| `backend/docs/FEATURE_WORKFLOW.md` | 1288 | ⚠️ MIXTO | Lines 15–55 duplican `docs/GETTING_STARTED.md`; el resto es valor. Tier 2.1. |
| `backend/docs/TESTING.md` | 766 | ⚠️ MIXTO | Lines 1–18 (TOC) y 694–755 (generic pytest) son trimables. Tier 2.3. |
| `backend/docs/prompts/backend-patterns.md` | 416 | ❓ DUDOSO | **8 referencias** activas (no es huérfano). Overlap con CLAUDE.md + rules. Tier 3.B. |

**Subtotal**: 10 archivos. Cero `.skill` zips. 4 trims + 1 decisión.

### 2.4 frontend submodule

| Archivo | Líneas / Tamaño | Estado | Notas |
|---|---|---|---|
| `frontend/CLAUDE.md` | 218 | ✅ ÚNICO | Frontend-specific, sin drift. |
| `frontend/.claude/skills/api-integration/SKILL.md` | (folder) | ✅ ÚNICO | Registrado en `settings.json`. |
| `frontend/.claude/skills/react-component/SKILL.md` | (folder) | ✅ ÚNICO | Idem. |
| `frontend/.claude/skills/react-feature/SKILL.md` | (folder) | ✅ ÚNICO | Idem. |
| `frontend/.claude/skills/react-form/SKILL.md` | (folder) | ✅ ÚNICO | Idem. |
| `frontend/.claude/skills/react-page/SKILL.md` | (folder) | ✅ ÚNICO | Idem. |
| `frontend/.claude/skills/api-integration.skill` | 3037 B | 📦 LEGACY | **0 referencias**. Tier 1. |
| `frontend/.claude/skills/react-component.skill` | 2871 B | 📦 LEGACY | **0 referencias**. Tier 1. |
| `frontend/.claude/skills/react-feature.skill` | 3776 B | 📦 LEGACY | **0 referencias**. Tier 1. |
| `frontend/.claude/skills/react-form.skill` | 3383 B | 📦 LEGACY | **0 referencias**. Tier 1. |
| `frontend/.claude/skills/react-page.skill` | 3161 B | 📦 LEGACY | **0 referencias**. Tier 1. |
| `frontend/docs/FEATURE_WORKFLOW.md` | 837 | ✅ ÚNICO | React-specific. |
| `frontend/docs/TESTING.md` | 778 | ✅ ÚNICO | Vitest + RTL patterns. |
| `frontend/docs/prompts/frontend-patterns.md` | 814 | ✅ ÚNICO | Reference impl deep-dive. |
| `frontend/docs/prompts/EXAMPLE_USAGE.md` | 634 | ✅ ÚNICO | CRUD examples (NOTA: distinto del root `docs/prompts/EXAMPLE_USAGE.md`). |

**Subtotal**: 15 archivos. **5 `.skill` archives legacy listos para eliminar**.

---

## 3. Análisis de redundancias

### 3.1 Duplicados estrictos detectados

**`.skill` archives en frontend** vs sus folder counterparts:

| Skill | `.skill` archive | `<name>/SKILL.md` folder | Contenido equivalente |
|---|---|---|---|
| api-integration | 3037 B | sí | sí (zip empaqueta el folder) |
| react-component | 2871 B | sí | sí |
| react-feature | 3776 B | sí | sí |
| react-form | 3383 B | sí | sí |
| react-page | 3161 B | sí | sí |

El framework Claude Code 2026 registra skills por **folder path**. Los archives `.skill` son artifacts de un formato anterior, no participan del registro, y no aparecen referenciados en ningún `.md / .json / .sh` del repo.

Precedente: el commit `4dae92f` ("chore(claude): remove duplicate .skill zip artifacts") del 2026-04-25 removió los mismos artifacts del scope **root**; el cleanup nunca se propagó al submódulo frontend.

### 3.2 Legacy huérfanos (no referenciados desde nadie)

- `docs/prompts/EXAMPLE_USAGE.md` (root, 747L) — 0 refs.
- `docs/prompts/custom-instructions.md` (root, 215L) — 0 refs. Describe setup legacy de Claude.ai Projects superseded por `.claude/skills/` + CLAUDE.md.

### 3.3 Solapamientos (overlap parcial)

- `backend/CLAUDE.md` § Database Strategy (92-102) vs root `CLAUDE.md` § Critical Gotchas — overlap conceptual; el ejemplo concreto agrega poco valor proyecto-específico.
- `backend/CLAUDE.md` línea 226 (`from_attributes` Pydantic) — gotcha genérica de Pydantic, no proyecto-específica.
- `backend/docs/FEATURE_WORKFLOW.md` líneas 15-55 (Quick Start / Prerequisites) vs `docs/GETTING_STARTED.md`.
- `backend/docs/TESTING.md` líneas 1-18 (TOC) y 694-755 (generic pytest troubleshooting).

### 3.4 Skills entre scopes — sin solapamiento real

| Scope | Skills | Naturaleza |
|---|---|---|
| Root | api-to-ui, backend-first, fullstack-feature | Cross-stack orchestrators (mezclan backend + frontend) |
| Backend | fastapi-endpoint, fastapi-migration, fastapi-model, fastapi-permission, fastapi-test, feature-from-plan | Layer-specific (modelo / endpoint / migración / permiso / test) |
| Frontend | api-integration, react-component, react-feature, react-form, react-page | Layer-specific (integración / componente / feature / form / página) |

Separación correcta. Ninguna acción.

### 3.5 CLAUDE.md múltiples — modelo ancestor/descendant correcto

| Archivo | Líneas | Scope | Overlap |
|---|---|---|---|
| `CLAUDE.md` (root) | 196 | Orchestration, monorepo, integration patterns, commit convention | ✅ sin duplicación |
| `backend/CLAUDE.md` | 281 | Backend-specific (FastAPI, SQLAlchemy, RBAC, multi-tenancy, alembic) | ⚠️ 2 sections genéricas (T2) |
| `frontend/CLAUDE.md` | 218 | Frontend-specific (TanStack Query, `<Can>`, httpOnly cookies) | ✅ overlap mínimo aceptable |

---

## 4. Grafo de referencias críticas

```
frontend/.claude/skills/api-integration.skill     ← 0 refs → safe delete
frontend/.claude/skills/react-component.skill     ← 0 refs → safe delete
frontend/.claude/skills/react-feature.skill       ← 0 refs → safe delete
frontend/.claude/skills/react-form.skill          ← 0 refs → safe delete
frontend/.claude/skills/react-page.skill          ← 0 refs → safe delete

docs/prompts/EXAMPLE_USAGE.md                     ← 0 refs → safe delete (T3.A user decision)
docs/prompts/custom-instructions.md               ← 0 refs → safe delete (T3.A user decision)

backend/docs/prompts/backend-patterns.md          ← 8 refs:
    - README.md:117
    - .claude/settings.json:135
    - .claude/skills/backend-first/SKILL.md:1120
    - .claude/skills/fullstack-feature/SKILL.md:1395
    - backend/.claude/skills/feature-from-plan/SKILL.md:380
    - docs/SKILLS_REFERENCE.md:798
    - docs/SKILLS_REFERENCE.md:907
    - docs/prompts/CLAUDE_PROJECT_SETUP.md:74
  → NOT a clean delete; consolidation requires 8 ref rewrites + content merge (T3.B user decision).
```

Verificación realizada con:
```bash
grep -rn "<basename>" /Users/julian/Desktop/Personal/saas-boilerplate \
  --include='*.md' --include='*.json' --include='*.sh' \
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.venv
```

---

## 5. Severidad de findings

| ID | Tipo | Archivo(s) | Tier propuesto |
|---|---|---|---|
| CLN-1 | 📦 LEGACY (delete clean) | `frontend/.claude/skills/*.skill` × 5 | T1 |
| CLN-2 | 🗑️ HUÉRFANO (delete pending decisión) | `docs/prompts/EXAMPLE_USAGE.md` | T3.A |
| CLN-3 | 🗑️ HUÉRFANO (delete pending decisión) | `docs/prompts/custom-instructions.md` | T3.A |
| CLN-4 | 🟡 OVERLAP (trim) | `backend/docs/FEATURE_WORKFLOW.md` lines 15-55 | T2.1 |
| CLN-5 | 🟡 OVERLAP (replace) | `backend/CLAUDE.md` lines 92-102 | T2.2 |
| CLN-6 | 🟡 OVERLAP (trim) | `backend/docs/TESTING.md` lines 1-18, 694-755 | T2.3 |
| CLN-7 | 🟡 GENERIC (replace with project example) | `backend/CLAUDE.md` line 226 | T2.4 |
| CLN-8 | ❓ CONSOLIDATION (refactor mayor) | `backend/docs/prompts/backend-patterns.md` | T3.B |
| CLN-9 | ❓ MAINTENANCE LIABILITY | `docs/SKILLS_REFERENCE.md` | T3.C |

---

## 6. Plan de remediación

Detalle tier-por-tier en `docs/plans/claude-cleanup.md`.
