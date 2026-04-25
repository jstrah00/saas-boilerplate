# Frontend API integration rules

Applies when editing: `frontend/src/api/**`, `frontend/src/features/**/api/**`, `frontend/src/features/**/hooks/**`.

## Types

- **Today**: domain types live in `frontend/src/types/models.ts` (hand-maintained, kept in sync with backend manually). Every feature imports from there: `import type { User, Item } from '@/types/models'`.
- **Target**: migrate to `frontend/src/types/generated/api.ts`, auto-generated from `http://localhost:8000/openapi.json` via `cd frontend && npm run generate:types`. Until that migration runs, `src/types/generated/` exists empty in the tree.
- When you add a backend field, update `models.ts` so the frontend stays type-correct — and re-run `npm run generate:types` if you're working with the OpenAPI doc to keep the future migration cheap.
- NEVER edit `src/types/generated/api.ts` directly once it exists (auto-generated).

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

## Permission gates

Three primitives, all reading the same Zustand permission list — pick the right one for the surface:

- **`<ProtectedRoute requiredPermissions={[...]}>`** (`src/routes/protected-route.tsx`) — route-level gate. Wraps a page; redirects to `/unauthorized` on miss.
- **`<Can perform="users:read" yes={...} no={...}>`** (`src/components/can.tsx`) — JSX-level gate. Use to show/hide elements inside a component (e.g. sidebar items, action buttons).
- **`usePermissions()`** (`src/hooks/use-permissions.ts`) — programmatic checks for hooks/handlers where JSX doesn't fit.

Avoid hand-rolling `user.permissions.includes('foo')` checks when one of the three would do.
