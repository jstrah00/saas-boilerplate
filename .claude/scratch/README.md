# `.claude/scratch/`

Trabajo efímero de Claude. Esta carpeta está **gitignored** — nada de lo que se escribe acá se versiona.

## Para qué

- `audits/` — auditorías meta sobre el setup de Claude (alignment de docs, drift entre código y reglas, cleanup de archivos legacy). Útiles mientras se trabaja, sin valor histórico una vez aplicadas.
- `plans/` — planes tácticos que acompañan a esos audits (cleanup, alignment, reshufles chicos).

## Convenciones

- Borrar libremente cuando ya no es útil. No requieren preservación en git.
- Si un plan termina materializando una decisión arquitectónica que vale conservar, **promoverla** a `docs/adr/` antes de borrar.
- Si un plan describe trabajo de feature de >1 día que vale trackear committeado, moverlo a `docs/plans/active/`.

## Por qué no `docs/`

Los plans/audits sobre el setup mismo son churn — no son patrimonio del proyecto. Mantenerlos acá saca ruido del repo y deja `docs/` para arquitectura, workflows y decisiones reales.
