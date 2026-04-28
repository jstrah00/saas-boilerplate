# Backend migration rules

Applies when editing: `backend/alembic/**`, `backend/app/models/**`.

## Workflow (autogenerate only)

1. Modify the model in `backend/app/models/postgres/*.py` (or `mongodb/`).
2. Confirm the model is imported in `backend/alembic/env.py` — otherwise autogenerate misses it.
3. `uv run alembic revision --autogenerate -m "<descriptive>"`.
4. **Read the generated SQL line by line** before applying. Watch for: missing `nullable`, missing indexes, type mismatches, accidental drops, data-loss operations.
5. Apply: `uv run alembic upgrade head`.

## Hard rules

- NEVER edit a migration that is already committed (the `protect-files.sh` hook also blocks this). Fix-forward with a new migration.
- NEVER hand-write a migration unless autogenerate cannot represent the operation (rare: data backfills).
- NEVER skip the SQL review step.

## Schema ownership

Alembic is the single source of truth for the PostgreSQL schema in **all** environments (dev / staging / prod). `init_postgres()` was removed during the 2026-04-25 alignment work — the empty-schema bootstrap path that bypassed migrations no longer exists. Every new model needs its corresponding migration. If you ever see direct `Base.metadata.create_all()` reintroduced for application schema, it's a regression — fix-forward by removing it and verifying every table has a migration.
