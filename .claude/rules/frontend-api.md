# Frontend API integration rules

Applies when editing: `frontend/src/api/**`, `frontend/src/features/**/api/**`, `frontend/src/features/**/hooks/**`.

## Types

- Types come from `frontend/src/types/generated/api.ts` (auto-generated from `http://localhost:8000/openapi.json`).
- Regenerate after backend schema changes: `cd frontend && npm run generate:types`.
- NEVER hand-write API request/response types — always import from generated.
- NEVER edit `src/types/generated/api.ts` directly.

## HTTP client

- Use `apiClient` from `frontend/src/api/client.ts` (axios instance with `withCredentials: true` for httpOnly cookies).
- NEVER use `fetch()` directly for backend calls.
- NEVER attach `Authorization: Bearer <token>` manually — auth flows via httpOnly cookies (since the 2026-02-06 migration).

## Error handling

- Errors are caught by interceptors in `frontend/src/api/interceptors.ts`. They surface via global toast for mutations or inline UI for queries.
- Avoid `try/catch` in components for network errors. Branch on the React Query result (`error`, `isError`) when needed.

## Query keys

- Keep query keys consistent within a feature: `['users']`, `['users', id]`, `['items', { ownerId }]`.
- Invalidate aggressively after mutations: `queryClient.invalidateQueries({ queryKey: ['items'] })`.
