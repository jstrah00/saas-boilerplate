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

## Initial-schema drift note

`init_postgres()` in `backend/app/main.py:106-107` currently creates initial schema directly in dev. This bypasses Alembic and risks drift in prod. New tables MUST also have a corresponding Alembic migration so prod gets them.
