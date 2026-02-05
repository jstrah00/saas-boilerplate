# Permission System Guide

Complete guide to the Role-Based Access Control (RBAC) system in the SaaS Boilerplate.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Current Implementation](#current-implementation)
- [Backend Implementation](#backend-implementation)
- [Frontend Implementation](#frontend-implementation)
- [Adding New Permissions](#adding-new-permissions)
- [Permission Migration Roadmap](#permission-migration-roadmap)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

The SaaS Boilerplate uses a flexible Role-Based Access Control (RBAC) system where:
- **Users** have **Roles**
- **Roles** have **Permissions**
- **Endpoints** require **Permissions**
- **Frontend** checks permissions for UX (backend enforces security)

### Permission Format

```
resource:action
```

Examples:
- `users:read` - View users
- `users:write` - Create/update users
- `users:delete` - Delete users
- `products:read` - View products
- `reports:export` - Export reports

---

## Architecture

### Database Schema

```
┌─────────┐ ┌──────────────────┐ ┌─────────────┐
│ User │──────│ role_permissions │──────│ Permission │
└─────────┘ └──────────────────┘ └─────────────┘
 │ │
 │ │
 │ ┌──────┐ │
 └────────────│ Role │──────────────────────────┘
 └──────┘
```

**Users**: `id`, `email`, `role_id`, etc.
**Roles**: `id`, `name` (admin, user, premium, etc.)
**Permissions**: `id`, `name` (users:read, etc.)
**role_permissions**: Junction table (role_id, permission_id)

### Permission Flow

```
1. User makes request
 ↓
2. Backend extracts JWT token
 ↓
3. Get user from token
 ↓
4. Load user's role
 ↓
5. Load role's permissions
 ↓
6. Check if required permission exists
 ↓
7. Allow or deny request
```

---

## Current Implementation

### [!] Important: Transition State

**Current Status** (as of v1.0):
- Backend: [X] Full RBAC with permissions
- Frontend: [!] Simplified permission check based on `is_admin` flag

**Why**: Frontend was implemented before backend RBAC was complete. The frontend uses a temporary permission system based on user's admin status.

**Migration Path**: See [Permission Migration Roadmap](#permission-migration-roadmap)

---

## Backend Implementation

### 1. Permission Definition

Permissions are defined in `backend/app/common/permissions.py`:

```python
from enum import Enum

class Permission(str, Enum):
 """Enumeration of all permissions in the system."""

 # User management
 USERS_READ = "users:read"
 USERS_WRITE = "users:write"
 USERS_DELETE = "users:delete"

 # Product management
 PRODUCTS_READ = "products:read"
 PRODUCTS_WRITE = "products:write"
 PRODUCTS_DELETE = "products:delete"

 # Reports
 REPORTS_READ = "reports:read"
 REPORTS_EXPORT = "reports:export"

 # Admin only
 ADMIN_PANEL = "admin:panel"
 SYSTEM_SETTINGS = "system:settings"
```

### 2. Role-Permission Mapping

Define which permissions belong to each role:

```python
# backend/app/common/permissions.py
from app.models.role import Role

ROLE_PERMISSIONS = {
 Role.ADMIN: {
 # Admin has all permissions
 Permission.USERS_READ,
 Permission.USERS_WRITE,
 Permission.USERS_DELETE,
 Permission.PRODUCTS_READ,
 Permission.PRODUCTS_WRITE,
 Permission.PRODUCTS_DELETE,
 Permission.REPORTS_READ,
 Permission.REPORTS_EXPORT,
 Permission.ADMIN_PANEL,
 Permission.SYSTEM_SETTINGS,
 },
 Role.USER: {
 # Regular user has limited permissions
 Permission.PRODUCTS_READ,
 Permission.REPORTS_READ,
 },
 Role.PREMIUM: {
 # Premium user has additional permissions
 Permission.PRODUCTS_READ,
 Permission.REPORTS_READ,
 Permission.REPORTS_EXPORT, # Premium feature
 },
}

def get_role_permissions(role: Role) -> set[Permission]:
 """Get all permissions for a role."""
 return ROLE_PERMISSIONS.get(role, set())
```

### 3. Permission Check Decorator

Use `@require_permissions()` to protect endpoints:

```python
# backend/app/api/v1/endpoints/users.py
from fastapi import APIRouter, Depends
from app.common.dependencies import require_permissions, get_current_user
from app.common.permissions import Permission
from app.models.user import User

router = APIRouter()

@router.get("/users")
async def list_users(
 current_user: User = Depends(require_permissions(Permission.USERS_READ))
):
 """List users - requires USERS_READ permission."""
 # Permission already checked by decorator
 # This code only runs if user has permission
 return await user_service.list_users()

@router.delete("/users/{user_id}")
async def delete_user(
 user_id: UUID,
 current_user: User = Depends(require_permissions(Permission.USERS_DELETE))
):
 """Delete user - requires USERS_DELETE permission."""
 return await user_service.delete_user(user_id)
```

### 4. Permission Check Implementation

The `require_permissions()` dependency (in `backend/app/common/dependencies.py`):

```python
from fastapi import Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.common.security import get_current_user_from_token
from app.common.permissions import Permission, get_role_permissions

def require_permissions(*required_permissions: Permission):
 """Create dependency that checks if user has required permissions.

 Usage:
 @router.get("/admin")
 async def admin_route(
 user: User = Depends(require_permissions(Permission.ADMIN_PANEL))
 ):
 ...
 """
 async def permission_checker(
 token: str = Depends(oauth2_scheme),
 db: AsyncSession = Depends(get_db)
 ):
 # Get user from token
 user = await get_current_user_from_token(token, db)

 if not user:
 raise HTTPException(
 status_code=status.HTTP_401_UNAUTHORIZED,
 detail="Not authenticated"
 )

 # Get user's permissions based on role
 user_permissions = get_role_permissions(user.role)

 # Check if user has all required permissions
 missing_permissions = set(required_permissions) - user_permissions

 if missing_permissions:
 raise HTTPException(
 status_code=status.HTTP_403_FORBIDDEN,
 detail=f"Missing permissions: {', '.join(p.value for p in missing_permissions)}"
 )

 return user

 return permission_checker
```

### 5. Adding User Permissions to JWT Token (Optional)

For better performance, include permissions in JWT token:

```python
# backend/app/common/security.py
def create_access_token(user: User) -> str:
 """Create JWT access token with user permissions."""
 permissions = [p.value for p in get_role_permissions(user.role)]

 payload = {
 "sub": str(user.id),
 "email": user.email,
 "role": user.role.value,
 "permissions": permissions, # Include permissions in token
 "exp": datetime.utcnow() + timedelta(minutes=30)
 }

 return jwt.encode(payload, SECRET_KEY, algorithm="HS256")
```

---

## Frontend Implementation

### Current Implementation (Temporary)

The frontend currently uses a simplified permission system based on `is_admin`:

```typescript
// frontend/src/hooks/use-permissions.ts
export const usePermissions = () => {
 const user = useAuthStore((state) => state.user);

 const hasPermission = (permission: string): boolean => {
 if (!user) return false;

 // TEMPORARY: Simple admin check
 // TODO: Replace with actual permission check from backend
 if (user.is_admin) {
 return true; // Admins have all permissions
 }

 // Regular users have limited permissions
 const userPermissions = [
 'products:read',
 'reports:read',
 ];

 return userPermissions.includes(permission);
 };

 return { hasPermission };
};
```

### Target Implementation (After Migration)

The frontend should check permissions from user data:

```typescript
// frontend/src/hooks/use-permissions.ts
export const usePermissions = () => {
 const user = useAuthStore((state) => state.user);

 const hasPermission = (permission: string): boolean => {
 if (!user || !user.permissions) return false;

 // Check if user has the specific permission
 return user.permissions.includes(permission);
 };

 const hasAnyPermission = (...permissions: string[]): boolean => {
 return permissions.some(hasPermission);
 };

 const hasAllPermissions = (...permissions: string[]): boolean => {
 return permissions.every(hasPermission);
 };

 return {
 hasPermission,
 hasAnyPermission,
 hasAllPermissions,
 };
};
```

### Permission Component

Use `<Can>` component to conditionally render UI:

```typescript
// frontend/src/components/auth/Can.tsx
import { usePermissions } from '@/hooks/use-permissions';

interface CanProps {
 permission: string;
 children: React.ReactNode;
 fallback?: React.ReactNode;
}

export const Can = ({ permission, children, fallback = null }: CanProps) => {
 const { hasPermission } = usePermissions();

 if (!hasPermission(permission)) {
 return <>{fallback}</>;
 }

 return <>{children}</>;
};
```

**Usage**:
```tsx
// Hide button if user doesn't have permission
<Can permission="users:delete">
 <Button variant="destructive">Delete User</Button>
</Can>

// Show different UI for users without permission
<Can
 permission="reports:export"
 fallback={<Button disabled>Upgrade to Premium</Button>}
>
 <Button>Export Report</Button>
</Can>
```

### Protected Routes

```typescript
// frontend/src/components/auth/ProtectedRoute.tsx
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/hooks/use-auth';
import { usePermissions } from '@/hooks/use-permissions';

interface ProtectedRouteProps {
 children: React.ReactNode;
 requiredPermissions?: string[];
}

export const ProtectedRoute = ({
 children,
 requiredPermissions = [],
}: ProtectedRouteProps) => {
 const { isAuthenticated } = useAuth();
 const { hasAllPermissions } = usePermissions();

 if (!isAuthenticated) {
 return <Navigate to="/login" replace />;
 }

 if (requiredPermissions.length > 0 && !hasAllPermissions(...requiredPermissions)) {
 return <Navigate to="/unauthorized" replace />;
 }

 return <>{children}</>;
};
```

**Usage**:
```tsx
// In router configuration
<Route
 path="/admin/users"
 element={
 <ProtectedRoute requiredPermissions={['users:read']}>
 <UsersPage />
 </ProtectedRoute>
 }
/>
```

---

## Adding New Permissions

### Step-by-Step Guide

**1. Define Permission** (Backend):
```python
# backend/app/common/permissions.py
class Permission(str, Enum):
 # ... existing permissions
 INVOICES_READ = "invoices:read"
 INVOICES_WRITE = "invoices:write"
 INVOICES_EXPORT = "invoices:export"
```

**2. Assign to Roles**:
```python
# backend/app/common/permissions.py
ROLE_PERMISSIONS = {
 Role.ADMIN: {
 # ... existing permissions
 Permission.INVOICES_READ,
 Permission.INVOICES_WRITE,
 Permission.INVOICES_EXPORT,
 },
 Role.USER: {
 # ... existing permissions
 Permission.INVOICES_READ, # Users can view their own invoices
 },
}
```

**3. Create Migration** (if storing in database):
```bash
cd backend
uv run alembic revision -m "add invoice permissions"
```

**Edit migration**:
```python
def upgrade():
 op.execute("""
 INSERT INTO permissions (name, description)
 VALUES
 ('invoices:read', 'View invoices'),
 ('invoices:write', 'Create and edit invoices'),
 ('invoices:export', 'Export invoices to PDF');
 """)

 # Assign to admin role
 op.execute("""
 INSERT INTO role_permissions (role_id, permission_id)
 SELECT r.id, p.id
 FROM roles r
 CROSS JOIN permissions p
 WHERE r.name = 'admin'
 AND p.name IN ('invoices:read', 'invoices:write', 'invoices:export');
 """)

 # Assign invoices:read to user role
 op.execute("""
 INSERT INTO role_permissions (role_id, permission_id)
 SELECT r.id, p.id
 FROM roles r
 CROSS JOIN permissions p
 WHERE r.name = 'user' AND p.name = 'invoices:read';
 """)

def downgrade():
 op.execute("""
 DELETE FROM permissions
 WHERE name IN ('invoices:read', 'invoices:write', 'invoices:export');
 """)
```

**Apply migration**:
```bash
uv run alembic upgrade head
```

**4. Protect Endpoints**:
```python
# backend/app/api/v1/endpoints/invoices.py
@router.get("/invoices")
async def list_invoices(
 current_user: User = Depends(require_permissions(Permission.INVOICES_READ))
):
 return await invoice_service.list_invoices(user_id=current_user.id)

@router.post("/invoices")
async def create_invoice(
 data: InvoiceCreate,
 current_user: User = Depends(require_permissions(Permission.INVOICES_WRITE))
):
 return await invoice_service.create_invoice(data, current_user.id)
```

**5. Update Frontend** (after migration):
```typescript
// Use in components
<Can permission="invoices:export">
 <Button onClick={exportToPDF}>Export to PDF</Button>
</Can>

// Use in routes
<Route
 path="/invoices"
 element={
 <ProtectedRoute requiredPermissions={['invoices:read']}>
 <InvoicesPage />
 </ProtectedRoute>
 }
/>
```

---

## Permission Migration Roadmap

### Phase 1: Backend Permissions [X] (Complete)

- [x] Permission enum defined
- [x] Role-permission mapping
- [x] `require_permissions()` decorator
- [x] Database schema for permissions
- [x] All endpoints protected

### Phase 2: Backend Sends Permissions (Next)

**Goal**: Include user permissions in authentication responses

**Changes needed**:

1. **Update UserResponse schema**:
```python
# backend/app/schemas/user.py
class UserResponse(BaseModel):
 id: UUID
 email: str
 role: Role
 permissions: list[str] # ← Add this
 # ... other fields

 @classmethod
 def from_user(cls, user: User) -> "UserResponse":
 permissions = [p.value for p in get_role_permissions(user.role)]
 return cls(
 id=user.id,
 email=user.email,
 role=user.role,
 permissions=permissions, # ← Include permissions
 # ... other fields
 )
```

2. **Update login response**:
```python
# backend/app/api/v1/endpoints/auth.py
@router.post("/login", response_model=TokenResponse)
async def login(...):
 # ... authentication logic

 # Include permissions in response
 permissions = [p.value for p in get_role_permissions(user.role)]

 return {
 "access_token": access_token,
 "refresh_token": refresh_token,
 "token_type": "bearer",
 "user": UserResponse.from_user(user), # ← Includes permissions
 }
```

3. **Update /me endpoint**:
```python
@router.get("/users/me", response_model=UserResponse)
async def get_current_user(
 current_user: User = Depends(get_current_user)
):
 return UserResponse.from_user(current_user)
```

### Phase 3: Frontend Consumes Permissions (Next)

**Goal**: Frontend uses actual permissions from backend

**Changes needed**:

1. **Update User type**:
```typescript
// frontend/src/types/models.ts
export interface User {
 id: string;
 email: string;
 role: string;
 permissions: string[]; // ← Add this
 // ... other fields
}
```

2. **Update auth store**:
```typescript
// frontend/src/store/slices/auth-slice.ts
interface AuthState {
 user: User | null;
 // ... other fields
}

// Login action stores user with permissions
login: async (credentials) => {
 const response = await authApi.login(credentials);

 // Store user (which now includes permissions)
 set({
 user: response.user, // ← Has permissions from backend
 token: response.access_token,
 });
},
```

3. **Update usePermissions hook**:
```typescript
// frontend/src/hooks/use-permissions.ts
export const usePermissions = () => {
 const user = useAuthStore((state) => state.user);

 const hasPermission = (permission: string): boolean => {
 if (!user || !user.permissions) return false;
 return user.permissions.includes(permission); // ← Use actual permissions
 };

 return { hasPermission };
};
```

4. **Remove temporary admin checks**:
```diff
- if (user.is_admin) return true;
+ // Permission check now based on actual permissions from backend
```

5. **Update components**:
No changes needed! Components using `<Can>` and `hasPermission()` will automatically use new system.

### Phase 4: Testing & Verification

- [ ] Backend sends correct permissions for each role
- [ ] Frontend receives and stores permissions
- [ ] `<Can>` component works with actual permissions
- [ ] ProtectedRoute works with actual permissions
- [ ] Permission changes in backend immediately reflect in frontend (after re-login)

---

## Best Practices

### 1. Principle of Least Privilege

Give users **minimum permissions** needed for their role:

```python
# [-] Bad: Give users all permissions
Role.USER: {Permission.USERS_DELETE, Permission.SYSTEM_SETTINGS}

# [X] Good: Give users only what they need
Role.USER: {Permission.PRODUCTS_READ, Permission.REPORTS_READ}
```

### 2. Granular Permissions

Use specific permissions rather than broad ones:

```python
# [-] Bad: Too broad
Permission.ADMIN = "admin" # All-or-nothing

# [X] Good: Granular
Permission.USERS_READ = "users:read"
Permission.USERS_WRITE = "users:write"
Permission.USERS_DELETE = "users:delete"
```

### 3. Security Boundary at Backend

**Always enforce permissions on backend**, frontend checks are UX only:

```python
# [X] Backend: Security boundary
@router.delete("/users/{user_id}")
async def delete_user(
 current_user: User = Depends(require_permissions(Permission.USERS_DELETE))
):
 # Permission checked - secure
```

```typescript
// Frontend: UX only (can be bypassed)
<Can permission="users:delete">
 <Button>Delete</Button>
</Can>
```

### 4. Audit Permission Changes

Log when permissions are checked:

```python
# backend/app/common/dependencies.py
logger.info(
 "permission_check",
 user_id=user.id,
 required=required_permissions,
 result="allowed" if has_permission else "denied"
)
```

### 5. Document Permissions

Keep a registry of all permissions and their purpose:

```python
class Permission(str, Enum):
 """All system permissions.

 Format: resource:action

 Resources:
 - users: User management
 - products: Product catalog
 - reports: Reporting system
 - admin: Administrative functions
 """
 USERS_READ = "users:read" # View user list and profiles
 USERS_WRITE = "users:write" # Create and edit users
 # ...
```

---

## Troubleshooting

### Issue: 403 Forbidden on all requests

**Cause**: User lacks permission

**Solution**:
```bash
# Check user's role and permissions
docker compose exec postgres psql -U postgres -d saas_boilerplate
SELECT u.email, r.name FROM users u JOIN roles r ON u.role_id = r.id;

# Verify permissions assigned to role
SELECT p.name FROM role_permissions rp
JOIN permissions p ON rp.permission_id = p.id
WHERE rp.role_id = (SELECT id FROM roles WHERE name = 'user');
```

### Issue: Frontend shows admin UI to non-admin

**Cause**: Using temporary `is_admin` check before migration complete

**Solution**: Complete Phase 2 & 3 of migration roadmap

### Issue: Permission changes don't reflect immediately

**Cause**: Permissions cached in JWT token or frontend state

**Solution**:
```typescript
// Force logout and re-login
authStore.logout();
// User re-logins, gets fresh token with updated permissions
```

---

## Additional Resources

- **Implementation**: See `backend/app/common/permissions.py`
- **Usage Examples**: `backend/app/api/v1/endpoints/users.py`
- **Frontend Hooks**: `frontend/src/hooks/use-permissions.ts`
- **Components**: `frontend/src/components/auth/Can.tsx`

---

**Last Updated**: 2026-02-05
**Status**: Backend complete, frontend migration in progress
