# Backend data-layer rules

Applies when editing: `backend/app/repositories/**`, `backend/app/services/**`, or anything that touches the DB.

## Repository pattern (mandatory)

- All DB access goes through a class extending `BaseRepository[Model]` in `backend/app/repositories/base.py`.
- Endpoints in `backend/app/api/v1/*.py` MUST NOT call `db.execute(select(...))` directly — they take a repository via `Depends(...)` from `backend/app/api/deps.py`.
- Reuse `BaseRepository` methods (`get`, `get_all`, `create`, `update`, `delete`, `soft_delete`, `count`). Override only when needed.

## Pagination convention

All paginated list endpoints follow the same offset-limit shape:

- **Query params** (FastAPI signature): `skip: int = 0`, `limit: int = 100`.
- **Response schema**: `{<resource_key>: list[T], total: int, skip: int, limit: int}`.
- **Helper**: `BaseRepository.get_all(skip, limit, filters=None)` returns `list[T]`. The total comes from a separate `repo.count(filters=...)` call inside the service — the repository never returns a `(items, total)` tuple.

Reference: `backend/app/api/v1/items.py:95-109` + `backend/app/schemas/item.py:105-111`.

When adding a new paginated endpoint, mirror this shape — don't introduce `page/per_page`, cursor-based, or `{data, meta}` envelopes without aligning the existing endpoints first.

## Multi-tenancy & ownership (CRITICAL)

- Today there is **no** `Organization` model. Items are owned per-user via `owner_id` (FK to `users.id`).
- Every query that returns user-scoped data MUST filter by `owner_id` (or equivalent ownership column). Returning records owned by anyone else is a security bug.
- When `Organization` is introduced (future), all queries must additionally filter by `organization_id`. Add a regression test before that refactor.

## Service layer

- Business logic lives in `backend/app/services/*.py`. The service:
  - Receives Pydantic input.
  - Calls repos.
  - Hashes passwords with `app.common.security.get_password_hash()` — never in models.
  - Raises `ExpectedError` subclasses (`NotFoundError`, `AuthorizationError`, etc.) — never `HTTPException` directly. Handlers in `app/api/handlers.py` map them to status codes.
- The service does NOT know about FastAPI request/response.

## Logging

- Use `app.common.logging.get_logger(__name__)`. Structured logs with key=value, not f-strings.
- structlog already censors `password`/`token`/`secret`/`authorization`/`api_key`. Don't bypass by stringifying objects that contain these.
