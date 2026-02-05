# System Architecture

This document describes the technical architecture of the fullstack SaaS boilerplate, including technology decisions, data flow, and integration patterns.

## Overview Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ Frontend │
│ React + TypeScript + Vite (localhost:5173) │
│ │
│ ┌────────────┐ ┌──────────────┐ ┌────────────────┐ │
│ │ Components │ │ TanStack │ │ Type-Safe API │ │
│ │ (shadcn/ui)│─▶│ Query/Router │─▶│ Client (axios) │ │
│ └────────────┘ └──────────────┘ └────────┬───────┘ │
│ │ │
└──────────────────────────────────────────────┼───────────────┘
 │ HTTP + JWT
 ▼
┌─────────────────────────────────────────────────────────────┐
│ Backend │
│ FastAPI + Python 3.11+ (localhost:8000) │
│ │
│ ┌────────────┐ ┌──────────┐ ┌────────────┐ ┌─────────┐ │
│ │ REST API │─▶│ Service │─▶│ Repository │─▶│ Models │ │
│ │ (Routes) │ │ Layer │ │ Layer │ │ (ORM) │ │
│ └────────────┘ └──────────┘ └────────────┘ └────┬────┘ │
│ │ │
└───────────────────────────────────────────────────────┼───────┘
 │
 ┌──────────────────────────────┴─────┐
 ▼ ▼
 ┌──────────────────┐ ┌──────────────────┐
 │ PostgreSQL │ │ MongoDB │
 │ (port 5432) │ │ (port 27017) │
 │ │ │ │
 │ - Users │ │ - Logs │
 │ - Roles │ │ - Events │
 │ - Permissions │ │ - Flexible data │
 └──────────────────┘ └──────────────────┘
```

## Technology Stack

### Backend
- **Framework**: FastAPI 0.100+ (async ASGI)
- **Language**: Python 3.11+ with type hints
- **ORM**: SQLAlchemy 2.0+ (async) for PostgreSQL
- **ODM**: Motor (async) for MongoDB
- **Migrations**: Alembic
- **Validation**: Pydantic V2
- **Testing**: pytest + pytest-asyncio
- **API Docs**: OpenAPI 3.0 (auto-generated)

**Key Dependencies**:
- `fastapi` - Web framework
- `sqlalchemy[asyncio]` - PostgreSQL ORM
- `motor` - MongoDB async driver
- `alembic` - Database migrations
- `pydantic` - Data validation
- `python-jose` - JWT tokens
- `passlib` - Password hashing

### Frontend
- **Framework**: React 18+ with TypeScript 5+
- **Build Tool**: Vite 5+
- **Routing**: TanStack Router (type-safe)
- **State**: TanStack Query (server state) + Zustand (client state)
- **Forms**: react-hook-form + Zod validation
- **UI**: shadcn/ui + Tailwind CSS
- **HTTP**: axios with interceptors
- **Type Generation**: openapi-typescript-codegen

**Key Dependencies**:
- `react` + `react-dom` - UI library
- `@tanstack/react-router` - Type-safe routing
- `@tanstack/react-query` - Server state management
- `zustand` - Client state management
- `react-hook-form` - Form handling
- `zod` - Schema validation
- `axios` - HTTP client
- `tailwindcss` - Utility CSS

### Infrastructure
- **Containerization**: Docker + Docker Compose
- **Databases**: PostgreSQL 15+ | MongoDB 6+
- **Dev Tools**: pgAdmin (PostgreSQL UI) | mongo-express (MongoDB UI)

## Dual Database Strategy

**Important**: MongoDB is **optional**. The boilerplate supports:
- [X] **PostgreSQL only** (recommended for most projects)
- [X] **PostgreSQL + MongoDB** (for high-volume logging/analytics)
- [X] **MongoDB only** (less common, requires code modifications)

**When you DON'T need MongoDB**:
- Simple CRUD applications
- Traditional web apps with relational data only
- Projects without high-volume logging/analytics
- MVP/prototypes

**When you DO need MongoDB**:
- Storing millions of log entries
- Real-time analytics with flexible schemas
- Event sourcing patterns
- Temporary/cache data with TTL

### PostgreSQL (Relational - Primary)

**Use For**:
- User management (authentication, profiles)
- Roles & permissions (RBAC)
- Transactional data requiring ACID guarantees
- Complex relationships (foreign keys, joins)
- Data with strict schema requirements

**Example Models**:
```python
# backend/app/models/user.py
class User(Base):
 __tablename__ = "users"

 id: Mapped[UUID] = mapped_column(primary_key=True)
 email: Mapped[str] = mapped_column(unique=True, index=True)
 hashed_password: Mapped[str]

 # Relationships
 roles: Mapped[list["Role"]] = relationship(secondary=user_roles)
```

**Access Pattern**: SQLAlchemy async sessions via Repository layer

### MongoDB (Document - Secondary)

**Use For**:
- Event logs & audit trails
- Analytics data & metrics
- Flexible schemas (varying structure)
- High write throughput
- Temporary/cached data

**Example Collections**:
```python
# backend/app/repositories/mongodb/event_repository.py
{
 "_id": ObjectId("..."),
 "event_type": "user_login",
 "user_id": "uuid-here",
 "timestamp": ISODate("2024-01-15T10:30:00Z"),
 "metadata": { # Flexible structure
 "ip_address": "192.168.1.1",
 "user_agent": "...",
 "custom_field": "..."
 }
}
```

**Access Pattern**: Motor async client via dedicated repositories

### Decision Framework

**Choose PostgreSQL when**:
- [X] Strict schema required
- [X] Relationships are critical
- [X] ACID transactions needed
- [X] Complex queries (JOINs, aggregations)

**Choose MongoDB when**:
- [X] Schema flexibility needed
- [X] High write volume (logs, events)
- [X] Nested/hierarchical data
- [X] Temporary/cache data

**Don't**:
- [-] Store same logical data in both databases
- [-] Use MongoDB just because "NoSQL is faster"
- [-] Put critical transactional data in MongoDB

## Authentication Flow

### Login Process

```
┌─────────┐ ┌─────────┐ ┌──────────┐
│ Browser │ │ Backend │ │ Database │
└────┬────┘ └────┬────┘ └────┬─────┘
 │ │ │
 │ POST /api/v1/auth/login │ │
 │ {email, password} │ │
 ├─────────────────────────▶│ │
 │ │ Query user by email │
 │ ├─────────────────────────▶│
 │ │◀─────────────────────────┤
 │ │ User with hashed_password│
 │ │ │
 │ │ Verify password (bcrypt) │
 │ │ │
 │ │ Generate JWT tokens: │
 │ │ - access (30 min) │
 │ │ - refresh (7 days) │
 │ │ │
 │ {access_token, │ │
 │ refresh_token, │ │
 │ token_type: "bearer"} │ │
 │◀─────────────────────────┤ │
 │ │ │
 │ Store in localStorage │ │
 │ │ │
```

### Token Structure

**Access Token** (30 minutes):
```json
{
 "sub": "user-uuid",
 "email": "user@example.com",
 "roles": ["user"],
 "permissions": ["USERS_READ", "USERS_WRITE"],
 "exp": 1705320000
}
```

**Refresh Token** (7 days):
```json
{
 "sub": "user-uuid",
 "type": "refresh",
 "exp": 1705920000
}
```

### Token Refresh Flow

```
┌─────────┐ ┌─────────┐
│ Browser │ │ Backend │
└────┬────┘ └────┬────┘
 │ │
 │ API Request │
 │ Authorization: Bearer... │
 ├─────────────────────────▶│
 │ │ Verify access token
 │ │ [-] Expired
 │ │
 │ 401 Unauthorized │
 │◀─────────────────────────┤
 │ │
 │ POST /api/v1/auth/refresh│
 │ {refresh_token} │
 ├─────────────────────────▶│
 │ │ Verify refresh token
 │ │ [X] Valid
 │ │ Generate new access token
 │ │
 │ {access_token} │
 │◀─────────────────────────┤
 │ │
 │ Retry original request │
 │ with new token │
 ├─────────────────────────▶│
 │ │
```

**Frontend Implementation**: Axios interceptor automatically retries failed requests after refresh (see `frontend/src/api/client.ts`)

### Storage & Security

**Storage Location**: `localStorage`
- Key: `access_token`, `refresh_token`
- Alternative: Consider `httpOnly` cookies for production (immune to XSS)

**Security Measures**:
- [X] Passwords hashed with bcrypt (12 rounds)
- [X] JWT tokens signed with RS256 (private key)
- [X] Refresh tokens rotated on use (optional)
- [X] Short access token lifetime (30 min)
- [X] HTTPS only in production

**Don't**:
- [-] Store tokens in cookies without `httpOnly` flag
- [-] Log tokens (access or refresh)
- [-] Send tokens in URL parameters
- [-] Use weak signing algorithms (HS256 with weak secrets)

## Permission System

### Backend RBAC

**Permission Enum** (`backend/app/models/permission.py`):
```python
class Permission(str, Enum):
 USERS_READ = "users:read"
 USERS_WRITE = "users:write"
 USERS_DELETE = "users:delete"
 ROLES_MANAGE = "roles:manage"
 # ... add more as needed
```

**Endpoint Protection**:
```python
# backend/app/api/v1/users.py
from app.common.dependencies import require_permissions

@router.get("/users/{user_id}")
@require_permissions(Permission.USERS_READ)
async def get_user(user_id: UUID, current_user: User = Depends(get_current_user)):
 # Only users with USERS_READ permission can access
 ...
```

**Role Assignment** (`backend/app/models/role.py`):
```python
# Roles have many-to-many relationship with permissions
admin_role = Role(name="admin", permissions=[
 Permission.USERS_READ,
 Permission.USERS_WRITE,
 Permission.USERS_DELETE,
 Permission.ROLES_MANAGE
])

user_role = Role(name="user", permissions=[
 Permission.USERS_READ # Limited access
])
```

### Frontend Permission Checks

**Can Component** (`frontend/src/components/auth/Can.tsx`):
```typescript
// Show/hide UI based on permissions
<Can permission="USERS_DELETE">
 <Button onClick={handleDelete}>Delete User</Button>
</Can>

// Multiple permissions (all required)
<Can permissions={["USERS_WRITE", "ROLES_MANAGE"]}>
 <AdminPanel />
</Can>
```

**usePermissions Hook**:
```typescript
const { hasPermission, hasAllPermissions } = usePermissions();

// Programmatic checks
if (hasPermission("USERS_DELETE")) {
 // Show delete modal
}
```

### Critical Notes

- **Backend = Security Boundary**: Always enforce permissions on backend
- **Frontend = UX Only**: Frontend checks prevent UI clutter, not security
- **Type Safety**: Frontend Permission types auto-generated from backend enum via OpenAPI
- **Sync**: After adding backend permissions, run `npm run generate:types` in frontend

## Type Generation Flow

### Process

```
┌──────────────────────────────────────────────────────────────┐
│ 1. Backend: Define Pydantic Schemas │
│ backend/app/schemas/user.py │
│ │
│ class UserResponse(BaseModel): │
│ id: UUID │
│ email: str │
│ created_at: datetime │
└───────────────────────────┬──────────────────────────────────┘
 │
 ▼
┌──────────────────────────────────────────────────────────────┐
│ 2. Backend: FastAPI Auto-Generates OpenAPI Spec │
│ http://localhost:8000/openapi.json │
│ │
│ { │
│ "components": { │
│ "schemas": { │
│ "UserResponse": { │
│ "properties": { │
│ "id": {"type": "string", "format": "uuid"}, │
│ "email": {"type": "string"}, │
│ "created_at": {"type": "string", ...} │
│ } │
│ } │
│ } │
│ } │
│ } │
└───────────────────────────┬──────────────────────────────────┘
 │
 ▼
┌──────────────────────────────────────────────────────────────┐
│ 3. Frontend: Generate TypeScript Types │
│ cd frontend && npm run generate:types │
│ │
│ → Uses openapi-typescript-codegen │
│ → Reads http://localhost:8000/openapi.json │
│ → Writes to src/types/generated/api.ts │
└───────────────────────────┬──────────────────────────────────┘
 │
 ▼
┌──────────────────────────────────────────────────────────────┐
│ 4. Frontend: Import & Use Types │
│ src/features/users/api/users.ts │
│ │
│ import { UserResponse } from '@/types/generated/api'; │
│ │
│ export const getUser = async (id: string): │
│ Promise<UserResponse> => { │
│ const { data } = await apiClient.get(`/users/${id}`); │
│ return data; │
│ } │
└──────────────────────────────────────────────────────────────┘
```

### When to Regenerate

Run `npm run generate:types` in frontend/ after:
- [X] Adding/modifying Pydantic schemas in backend
- [X] Adding/removing API endpoints
- [X] Changing request/response models
- [X] Adding new Permission enum values

**Don't**:
- [-] Manually edit `src/types/generated/api.ts` (auto-generated)
- [-] Commit backend changes without regenerating types
- [-] Ignore TypeScript errors after regeneration (fix schemas)

## API Contract

### Endpoint Patterns

**Base URL**: `http://localhost:8000/api/v1`

**Resource Endpoints**:
```
GET /api/v1/users # List users (paginated)
POST /api/v1/users # Create user
GET /api/v1/users/{id} # Get single user
PUT /api/v1/users/{id} # Update user (full)
PATCH /api/v1/users/{id} # Update user (partial)
DELETE /api/v1/users/{id} # Delete user
```

### Response Format

**Success Response**:
```json
{
 "id": "uuid-here",
 "email": "user@example.com",
 "created_at": "2024-01-15T10:30:00Z"
}
```

**List Response** (Paginated):
```json
{
 "items": [
 {"id": "uuid-1", "email": "user1@example.com"},
 {"id": "uuid-2", "email": "user2@example.com"}
 ],
 "total": 100,
 "page": 1,
 "size": 10,
 "pages": 10
}
```

**Error Response**:
```json
{
 "detail": "User not found"
}
```

### Pagination

**Query Parameters**:
- `page` (default: 1) - Page number
- `size` (default: 10) - Items per page
- `sort` (optional) - Sort field (e.g., `created_at`)
- `order` (optional) - Sort order (`asc` | `desc`)

**Example**: `GET /api/v1/users?page=2&size=20&sort=created_at&order=desc`

## Error Handling

### Backend Exception Flow

```python
# backend/app/common/exceptions.py
class NotFoundException(HTTPException):
 def __init__(self, detail: str = "Resource not found"):
 super().__init__(status_code=404, detail=detail)

class UnauthorizedException(HTTPException):
 def __init__(self, detail: str = "Not authenticated"):
 super().__init__(status_code=401, detail=detail)

class ForbiddenException(HTTPException):
 def __init__(self, detail: str = "Insufficient permissions"):
 super().__init__(status_code=403, detail=detail)
```

**Usage in Endpoints**:
```python
user = await user_service.get_user(user_id)
if not user:
 raise NotFoundException(f"User {user_id} not found")
```

### Frontend Error Handling

**Axios Interceptor** (`frontend/src/api/client.ts`):
```typescript
apiClient.interceptors.response.use(
 (response) => response,
 async (error) => {
 if (error.response?.status === 401) {
 // Attempt token refresh
 await refreshToken();
 return apiClient.request(error.config);
 }

 // Show error toast for mutations
 if (error.config.method !== 'get') {
 toast.error(error.response?.data?.detail || 'An error occurred');
 }

 return Promise.reject(error);
 }
);
```

**TanStack Query Error Handling**:
```typescript
// Mutations - Show toast
const mutation = useMutation({
 mutationFn: createUser,
 onError: (error) => {
 toast.error(error.response?.data?.detail || 'Failed to create user');
 }
});

// Queries - Show inline UI
const { data, error, isError } = useQuery({
 queryKey: ['user', id],
 queryFn: () => getUser(id)
});

if (isError) {
 return <ErrorMessage>{error.message}</ErrorMessage>;
}
```

## Deployment Architecture

### Development

```
docker compose up -d

┌──────────────────┐ ┌──────────────────┐
│ Backend │ │ Frontend │
│ FastAPI │ │ Vite Dev Server │
│ Port: 8000 │ │ Port: 5173 │
│ Hot Reload: [X] │ │ Hot Reload: [X] │
└────────┬─────────┘ └────────┬─────────┘
 │ │
 └──────────┬──────────┘
 │
 ┌───────────────┴───────────────┐
 │ │
┌───▼──────────┐ ┌─────────▼────┐
│ PostgreSQL │ │ MongoDB │
│ Port: 5432 │ │ Port: 27017 │
└──────────────┘ └──────────────┘
```

### Production (TODO)

```
┌─────────────────┐
│ Nginx / Caddy │ (Reverse proxy)
│ Port: 80, 443 │
└────────┬────────┘
 │
 ┌────┴──────────────┐
 │ │
┌───▼────────┐ ┌──────▼─────┐
│ Frontend │ │ Backend │
│ Static │ │ Gunicorn + │
│ Build │ │ Uvicorn │
└────────────┘ └──────┬─────┘
 │
 ┌──────────────┴─────────────┐
 │ │
 ┌────▼─────┐ ┌──────▼────┐
 │ Postgres │ │ MongoDB │
 │ (Managed)│ │ (Managed) │
 └──────────┘ └───────────┘
```

**Environment Variables**:
- Development: `.env` files (gitignored)
- Production: Environment variables via container orchestration
- Secrets: Use secret management (AWS Secrets Manager, HashiCorp Vault, etc.)

**See**: Deployment guide (TODO) for production setup details.
