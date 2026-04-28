---
description: Auditá el proyecto contra best practices de Claude Code y (en caso de encontrarlas) aplicá mejoras en 3 fases (audit → plan → execute).
---

Vas a hacer una auditoría completa de este boilerplate y alinearlo con las mejores prácticas de Claude Code para proyectos SaaS en 2026. Tu objetivo es dejar el repo en un estado donde futuras sesiones de Claude operen como un senior engineer que ya conoce el proyecto, no como un autocomplete que tiene que redescubrir todo cada vez.

Trabajá en TRES FASES estrictas. NO pases a la siguiente fase sin mi aprobación explícita.

────────────────────────────────────────────────────────────
FASE 1 — DESCUBRIMIENTO (read-only, no edits)
────────────────────────────────────────────────────────────

Mapeá el estado actual del repo SIN modificar nada todavía.

1. Leé el root: `ls -la`, `cat package.json`, `cat README.md` si existe.
2. Detectá el stack real (framework, ORM, auth, payments, package manager, test runner).
3. Buscá archivos de configuración de agentes existentes:
   - CLAUDE.md, AGENTS.md, .cursorrules, .windsurfrules, copilot-instructions.md
   - .claude/ (settings.json, agents/, skills/, commands/, hooks/, rules/)
   - .mcp.json
4. Mapeá la estructura: monorepo o single app, dónde viven schema, server actions, DAL, auth, billing.
5. Identificá qué patrones YA SIGUE el proyecto y cuáles no:
   - ¿Hay un Data Access Layer (lib/dal.ts) o se hacen queries desde cualquier lado?
   - ¿Las server actions validan input con Zod?
   - ¿Las queries filtran por organizationId / tenantId?
   - ¿Hay ActionResult<T> o se tiran errores raw al cliente?
   - ¿Migraciones inmutables (auto-generadas) o hand-written?
   - ¿Hay tests? ¿De qué tipo? ¿Coverage?
   - ¿Qué hooks de Git/CI existen?

Para esta fase usá subagents en paralelo si están disponibles — delegá la exploración para no quemar contexto principal:
- Un explorador para auth
- Un explorador para data layer / multi-tenancy
- Un explorador para billing
- Un explorador para tests + CI
- Un explorador para la config existente de Claude/AI

ENTREGABLE de Fase 1 — escribilo a `docs/audits/claude-setup-audit-YYYY-MM-DD.md`:

```markdown
# Claude Code Setup Audit — [fecha]

## Stack detectado
[framework, ORM, auth, payments, runtime, package manager, test runner — versiones]

## Estructura
[monorepo o no, layout principal, dónde vive cada cosa]

## Estado actual de la config para AI
| Componente | Estado | Notas |
|---|---|---|
| CLAUDE.md | ❌ ausente / ⚠️ presente pero bloated / ✅ ok | ... |
| AGENTS.md | ... | ... |
| .claude/settings.json | ... | ... |
| .mcp.json | ... | ... |
| Subagents (.claude/agents/) | ... | qué hay |
| Skills (.claude/skills/) | ... | qué hay |
| Hooks (.claude/hooks/) | ... | qué hay |
| Path-scoped rules (.claude/rules/) | ... | qué hay |
| docs/ estructura | ... | qué docs existen |

## Estado actual de patrones del código
| Patrón | Estado | Evidencia (file:line) |
|---|---|---|
| Data Access Layer centralizado | ❌/⚠️/✅ | ... |
| Server actions con Zod validation | ... | ... |
| Multi-tenant isolation (orgId en queries) | ... | ... |
| ActionResult<T> shape | ... | ... |
| Migraciones inmutables auto-generadas | ... | ... |
| Idempotencia en webhooks | ... | ... |
| Soft delete pattern | ... | ... |
| Test factories | ... | ... |
| Cross-tenant tests | ... | ... |
| Conventional commits | ... | ... |

## Riesgos detectados (ordenados por severidad)
🔴 CRITICAL — gaps que pueden causar data leak, security issues, prod outage
🟡 HIGH — gaps que degradan calidad de output de Claude significativamente
🟢 MEDIUM — mejoras incrementales

[lista detallada con file:line refs]

## Inventario de gaps vs el target (best practices 2026)
[tabla completa: qué falta, qué hay que mejorar, qué está ok]
```

Cuando termines la Fase 1, PARÁ. Mostrame el path del audit y un resumen ejecutivo de 5-10 líneas. Esperá mi OK antes de seguir.

────────────────────────────────────────────────────────────
FASE 2 — PLAN DE REMEDIACIÓN (escribir, no aplicar)
────────────────────────────────────────────────────────────

Solo después de mi OK en Fase 1.

Generá un plan en `docs/plans/claude-setup-alignment.md` con esta estructura:

```markdown
# Plan: Alinear repo con best practices Claude Code 2026

## Resumen ejecutivo
[3-5 líneas: qué se va a hacer, qué NO se va a tocar, qué impacto esperar]

## Principios de este plan
- NO reescribir código de aplicación funcional. Solo alinear config + docs + agregar guardrails.
- NO romper tests existentes. Si algo está pasando ahora, sigue pasando después.
- Cambios al código fuente solo si cierran un gap CRITICAL (ej: query sin orgId).
- Cada cambio en archivo existente justificado con razón concreta.

## Cambios — Tier 1: Aditivos puros (zero riesgo)
Archivos NUEVOS que se crean sin tocar lo existente.

- [ ] Crear `CLAUDE.md` (si no existe) — entry point lean, <400 líneas, con @-refs
- [ ] Crear `AGENTS.md` espejo tool-agnostic
- [ ] Crear `.claude/settings.json` con permissions allow/ask/deny + hooks
- [ ] Crear `.claude/hooks/protect-bash.sh` (block rm -rf, force push, prod-touching)
- [ ] Crear `.claude/hooks/protect-files.sh` (block edits a .env y migraciones committeadas)
- [ ] Crear `.claude/hooks/scan-secrets.sh` (block prompts con AWS keys, Stripe keys, JWTs)
- [ ] Crear `.claude/hooks/typecheck-on-stop.sh` (backpressure)
- [ ] Crear `.claude/hooks/format-on-save.sh` (non-blocking prettier)
- [ ] Crear subagents en `.claude/agents/`:
  - code-reviewer (read-only)
  - security-reviewer (Opus, worktree, multi-tenant aware)
  - test-writer (TDD)
  - db-architect (schema + migrations)
  - typescript-fixer (no `any`)
  - codebase-explorer (Haiku, cheap research)
- [ ] Crear skills en `.claude/skills/`:
  - plan-feature
  - review-pr
  - db-migration
  - write-tests
  - deploy-staging (manual-only)
  - update-docs
- [ ] Crear slash commands en `.claude/commands/`: /catchup, /ship
- [ ] Crear `.claude/rules/` con reglas path-scoped:
  - actions.md (cuando edita src/actions/**)
  - db.md (cuando edita schema o migraciones)
- [ ] Crear `.mcp.json` con MCPs útiles (context7, github, postgres readonly, sentry)
- [ ] Crear `docs/`:
  - architecture.md (mapa del sistema, request lifecycle, multi-tenancy model)
  - database.md (rules de schema, migration policy, indexing)
  - api.md (server action conventions)
  - auth.md (RBAC, session model)
  - billing.md (Stripe integration, webhooks, idempotencia)
  - testing.md (Vitest + Playwright patterns)
  - gotchas.md (template para llenar con bugs reales)
- [ ] Agregar `.gitignore` entries: .claude/worktrees/, CLAUDE.local.md
- [ ] Agregar `.worktreeinclude` para parallel sessions

## Cambios — Tier 2: Modificaciones a archivos existentes
Cada uno con justificación. NO se aplican sin tu OK explícito.

- [ ] [archivo] — [qué cambia y por qué — referencia gap del audit]
- [ ] ...

## Cambios — Tier 3: Refactors de código (CRITICAL gaps únicamente)
Solo si el audit encontró cosas tipo "query sin orgId" o "secrets en source".
Cada uno con file:line, descripción del problema, fix propuesto, riesgo.

- [ ] [archivo:línea] — [problema] — [fix] — [riesgo: bajo/medio/alto]

## Lo que explícitamente NO voy a tocar
[lista. Por ejemplo: lógica de negocio existente, UI components, tests pasando, dependencias]

## Orden de ejecución
1. Tier 1 completo (aditivo, reversible con `rm`)
2. Tier 2 con review por cambio
3. Tier 3 uno por uno, con review individual

## Verificación post-aplicación
- pnpm typecheck pasa
- pnpm lint pasa  
- pnpm test pasa (sin nuevos failures)
- Claude Code arranca sin errores en hooks/settings
- /context muestra que CLAUDE.md y rules cargan correctamente
```

PARÁ. Mostrame el plan. Esperá mi OK explícito tier-por-tier (puedo aprobar Tier 1 y rechazar Tier 2, etc).

────────────────────────────────────────────────────────────
FASE 3 — EJECUCIÓN (incremental, con commits atómicos)
────────────────────────────────────────────────────────────

Solo después de mi OK por Tier.

Por cada Tier aprobado:

1. Trabajá en commits atómicos — un commit por cambio lógico, no un mega-commit.
2. Usá Conventional Commits: `chore(claude):`, `docs(claude):`, `feat(security):`, etc.
3. Después de CADA commit:
   - `pnpm typecheck && pnpm lint`
   - Si hay tests relevantes, `pnpm test --run` sobre el área afectada
4. Si algo falla, NO seguir adelante. Mostrame el error.
5. Al terminar el Tier, mostrame `git log --oneline` de los commits del tier y esperá OK para siguiente Tier.

Para Tier 3 (refactors de código): un commit por refactor + un test que demuestre el fix antes del cambio (regression test). Si no se puede testear, explicame por qué.

────────────────────────────────────────────────────────────
REGLAS GENERALES (aplican a todas las fases)
────────────────────────────────────────────────────────────

✅ HACER:
- Adaptarte al stack REAL del proyecto, no asumir que es Next.js/Drizzle/Stripe. Si es Remix+Prisma+Polar, ajustá ejemplos y subagents a eso.
- Detectar y respetar convenciones existentes. Si el proyecto usa default exports, NO impongas named exports — documentá lo que usa.
- Mantener todo edit reversible (commits atómicos).
- Preguntarme cuando haya ambigüedad real. UNA pregunta focalizada, no batería.
- Usar progressive disclosure: CLAUDE.md lean (<400 líneas), detalles en docs/, paths-scoped rules para reglas locales.

❌ NO HACER:
- NO instalar dependencias nuevas sin preguntar.
- NO reescribir lógica de negocio que ya funciona.
- NO modificar migraciones ya committeadas.
- NO tocar .env*, secretos, ni archivos en .gitignore.
- NO crear 50 subagents/skills "por si acaso". Mejor pocos y buenos.
- NO meter en CLAUDE.md cosas que un linter ya hace mejor (formato, naming) — eso degrada instruction-following uniformemente según research de HumanLayer.
- NO copiar pegar el boilerplate genérico si el proyecto ya tiene patrones distintos. Adaptá.

────────────────────────────────────────────────────────────
EMPEZÁ POR FASE 1 AHORA. NO PASES A FASE 2 SIN MI OK.
────────────────────────────────────────────────────────────
