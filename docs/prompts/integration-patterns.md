# API Integration Patterns

Detailed patterns for integrating frontend with backend API, including authentication, type safety, error handling, and permission checks.

## API Client Configuration

### Base Setup

**File**: `frontend/src/lib/api-client.ts`

```typescript
import axios, { AxiosError, AxiosRequestConfig } from 'axios';
import { toast } from 'sonner';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

export const apiClient = axios.create({
  baseURL: `${API_BASE_URL}/api/v1`,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000, // 30 seconds
});

// Add request interceptor for auth token
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Add response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as AxiosRequestConfig & { _retry?: boolean };

    // Handle 401 - Token expired, try to refresh
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        const refreshToken = localStorage.getItem('refresh_token');
        if (!refreshToken) {
          throw new Error('No refresh token');
        }

        const { data } = await axios.post(`${API_BASE_URL}/api/v1/auth/refresh`, {
          refresh_token: refreshToken,
        });

        localStorage.setItem('access_token', data.access_token);

        // Retry original request with new token
        if (originalRequest.headers) {
          originalRequest.headers.Authorization = `Bearer ${data.access_token}`;
        }
        return apiClient.request(originalRequest);
      } catch (refreshError) {
        // Refresh failed - logout user
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }

    // Handle 403 - Forbidden
    if (error.response?.status === 403) {
      toast.error('You do not have permission to perform this action');
    }

    // Handle other errors for mutations (non-GET requests)
    if (error.config?.method !== 'get') {
      const message = error.response?.data?.detail || 'An error occurred';
      toast.error(message);
    }

    return Promise.reject(error);
  }
);
```

### Environment Configuration

**File**: `frontend/.env`

```bash
# API URL (no trailing slash)
VITE_API_URL=http://localhost:8000

# Production
# VITE_API_URL=https://api.example.com
```

## Authentication Integration

### Login Flow

**File**: `frontend/src/features/auth/api/auth.ts`

```typescript
import { apiClient } from '@/lib/api-client';
import type { LoginRequest, TokenResponse } from '@/types/generated/api';

export const login = async (credentials: LoginRequest): Promise<TokenResponse> => {
  // Note: OAuth2 password flow uses form data, not JSON
  const formData = new URLSearchParams();
  formData.append('username', credentials.email);
  formData.append('password', credentials.password);

  const { data } = await apiClient.post<TokenResponse>('/auth/login', formData, {
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  });

  // Store tokens
  localStorage.setItem('access_token', data.access_token);
  localStorage.setItem('refresh_token', data.refresh_token);

  return data;
};

export const logout = async (): Promise<void> => {
  // Optional: Call backend logout endpoint to invalidate refresh token
  try {
    await apiClient.post('/auth/logout');
  } catch (error) {
    // Ignore errors, clear local storage anyway
  }

  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');
};

export const refreshAccessToken = async (): Promise<TokenResponse> => {
  const refreshToken = localStorage.getItem('refresh_token');
  if (!refreshToken) {
    throw new Error('No refresh token available');
  }

  const { data } = await apiClient.post<TokenResponse>('/auth/refresh', {
    refresh_token: refreshToken,
  });

  localStorage.setItem('access_token', data.access_token);

  // Optional: Rotate refresh token
  if (data.refresh_token) {
    localStorage.setItem('refresh_token', data.refresh_token);
  }

  return data;
};

export const getCurrentUser = async () => {
  const { data } = await apiClient.get('/auth/me');
  return data;
};
```

### Auth Hook

**File**: `frontend/src/features/auth/hooks/useAuth.ts`

```typescript
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from '@tanstack/react-router';
import { login, logout, getCurrentUser } from '../api/auth';
import type { LoginRequest } from '@/types/generated/api';

export const useAuth = () => {
  const queryClient = useQueryClient();
  const navigate = useNavigate();

  // Get current user
  const { data: user, isLoading } = useQuery({
    queryKey: ['auth', 'me'],
    queryFn: getCurrentUser,
    retry: false,
    // Only fetch if token exists
    enabled: !!localStorage.getItem('access_token'),
  });

  // Login mutation
  const loginMutation = useMutation({
    mutationFn: (credentials: LoginRequest) => login(credentials),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['auth', 'me'] });
      navigate({ to: '/dashboard' });
    },
  });

  // Logout mutation
  const logoutMutation = useMutation({
    mutationFn: logout,
    onSuccess: () => {
      queryClient.clear(); // Clear all cached data
      navigate({ to: '/login' });
    },
  });

  return {
    user,
    isLoading,
    isAuthenticated: !!user,
    login: loginMutation.mutate,
    logout: logoutMutation.mutate,
    isLoggingIn: loginMutation.isPending,
  };
};
```

### Protected Routes

**File**: `frontend/src/components/auth/ProtectedRoute.tsx`

```typescript
import { useAuth } from '@/features/auth/hooks/useAuth';
import { Navigate } from '@tanstack/react-router';
import { Loader2 } from 'lucide-react';

interface ProtectedRouteProps {
  children: React.ReactNode;
}

export const ProtectedRoute = ({ children }: ProtectedRouteProps) => {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" />;
  }

  return <>{children}</>;
};
```

## Type Safety

### Type Generation Process

**1. Backend exposes OpenAPI schema**:
```bash
# Access OpenAPI JSON
curl http://localhost:8000/openapi.json > openapi.json
```

**2. Frontend generates TypeScript types**:

**File**: `frontend/package.json`

```json
{
  "scripts": {
    "generate:types": "openapi-typescript-codegen --input http://localhost:8000/openapi.json --output ./src/types/generated --client axios"
  }
}
```

**Run**:
```bash
cd frontend
npm run generate:types
```

**3. Import and use types**:

```typescript
import type {
  UserResponse,
  UserCreate,
  UserUpdate,
  PaginatedResponse,
  Permission,
} from '@/types/generated/api';

// Fully typed API functions
export const getUsers = async (
  params?: { page?: number; size?: number }
): Promise<PaginatedResponse<UserResponse>> => {
  const { data } = await apiClient.get('/users', { params });
  return data;
};

export const createUser = async (user: UserCreate): Promise<UserResponse> => {
  const { data } = await apiClient.post('/users', user);
  return data;
};
```

### Custom Type Utilities

**File**: `frontend/src/types/api.ts`

```typescript
// Re-export generated types
export * from './generated/api';

// Add custom utilities
export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  size: number;
  pages: number;
}

export interface ApiError {
  detail: string;
  status?: number;
}

// Query params helper
export interface ListParams {
  page?: number;
  size?: number;
  sort?: string;
  order?: 'asc' | 'desc';
}

// Generic ID types
export type UUID = string;
export type Slug = string;
```

## Error Handling

### Backend Exception Structure

**Backend**: `backend/app/common/exceptions.py`

```python
from fastapi import HTTPException

class NotFoundException(HTTPException):
    def __init__(self, detail: str = "Resource not found"):
        super().__init__(status_code=404, detail=detail)

class ValidationException(HTTPException):
    def __init__(self, detail: str = "Validation error"):
        super().__init__(status_code=422, detail=detail)

class UnauthorizedException(HTTPException):
    def __init__(self, detail: str = "Not authenticated"):
        super().__init__(status_code=401, detail=detail)

class ForbiddenException(HTTPException):
    def __init__(self, detail: str = "Insufficient permissions"):
        super().__init__(status_code=403, detail=detail)
```

### Frontend Error Handling

**For Mutations (Create, Update, Delete)**:

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { createUser } from '../api/users';
import type { UserCreate } from '@/types/generated/api';

export const useCreateUser = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: UserCreate) => createUser(data),
    onSuccess: (newUser) => {
      // Invalidate and refetch users list
      queryClient.invalidateQueries({ queryKey: ['users'] });

      // Success toast (optional, interceptor already handles it)
      toast.success(`User ${newUser.email} created successfully`);
    },
    onError: (error: AxiosError<ApiError>) => {
      // Error toast shown by interceptor, but you can add custom logic
      console.error('Failed to create user:', error);

      // Custom error handling for specific errors
      if (error.response?.status === 409) {
        toast.error('A user with this email already exists');
      }
    },
  });
};

// Usage in component
const CreateUserForm = () => {
  const createUser = useCreateUser();

  const handleSubmit = (data: UserCreate) => {
    createUser.mutate(data);
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* Form fields */}
      <button type="submit" disabled={createUser.isPending}>
        {createUser.isPending ? 'Creating...' : 'Create User'}
      </button>
    </form>
  );
};
```

**For Queries (Read)**:

```typescript
import { useQuery } from '@tanstack/react-query';
import { getUser } from '../api/users';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Loader2 } from 'lucide-react';

export const useUser = (userId: string) => {
  return useQuery({
    queryKey: ['users', userId],
    queryFn: () => getUser(userId),
    retry: (failureCount, error) => {
      // Don't retry on 404 or 403
      if (error.response?.status === 404 || error.response?.status === 403) {
        return false;
      }
      return failureCount < 3;
    },
  });
};

// Usage in component
const UserDetail = ({ userId }: { userId: string }) => {
  const { data: user, isLoading, isError, error } = useUser(userId);

  if (isLoading) {
    return (
      <div className="flex justify-center p-8">
        <Loader2 className="h-8 w-8 animate-spin" />
      </div>
    );
  }

  if (isError) {
    return (
      <Alert variant="destructive">
        <AlertDescription>
          {error.response?.data?.detail || 'Failed to load user'}
        </AlertDescription>
      </Alert>
    );
  }

  return <div>{/* Render user data */}</div>;
};
```

### Global Error Boundary

**File**: `frontend/src/components/ErrorBoundary.tsx`

```typescript
import React from 'react';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';

interface ErrorBoundaryProps {
  children: React.ReactNode;
}

interface ErrorBoundaryState {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends React.Component<
  ErrorBoundaryProps,
  ErrorBoundaryState
> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
    // Optional: Send to error tracking service (Sentry, etc.)
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="flex h-screen items-center justify-center p-4">
          <Alert variant="destructive" className="max-w-lg">
            <AlertTitle>Something went wrong</AlertTitle>
            <AlertDescription className="mt-2">
              <p className="mb-4">
                {this.state.error?.message || 'An unexpected error occurred'}
              </p>
              <Button
                onClick={() => {
                  this.setState({ hasError: false, error: undefined });
                  window.location.href = '/';
                }}
              >
                Go to Home
              </Button>
            </AlertDescription>
          </Alert>
        </div>
      );
    }

    return this.props.children;
  }
}
```

## Permission Checks

### Backend Permission Enforcement

**Backend**: `backend/app/common/dependencies.py`

```python
from functools import wraps
from typing import Callable, List
from fastapi import Depends, HTTPException
from app.models.permission import Permission
from app.models.user import User
from app.common.auth import get_current_user

def require_permissions(*permissions: Permission):
    """Decorator to require specific permissions for endpoint access."""
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, current_user: User = Depends(get_current_user), **kwargs):
            user_permissions = {
                perm.name
                for role in current_user.roles
                for perm in role.permissions
            }

            required_perms = {perm.value for perm in permissions}

            if not required_perms.issubset(user_permissions):
                raise HTTPException(
                    status_code=403,
                    detail=f"Missing required permissions: {required_perms - user_permissions}"
                )

            return await func(*args, current_user=current_user, **kwargs)
        return wrapper
    return decorator
```

**Usage**:
```python
from app.common.dependencies import require_permissions
from app.models.permission import Permission

@router.delete("/users/{user_id}")
@require_permissions(Permission.USERS_DELETE)
async def delete_user(
    user_id: UUID,
    current_user: User = Depends(get_current_user)
):
    # Only users with USERS_DELETE permission can access
    ...
```

### Frontend Permission Components

**File**: `frontend/src/components/auth/Can.tsx`

```typescript
import { usePermissions } from '@/features/auth/hooks/usePermissions';
import type { Permission } from '@/types/generated/api';

interface CanProps {
  permission?: Permission;
  permissions?: Permission[];
  requireAll?: boolean; // If true, require all permissions; if false, require any
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

export const Can = ({
  permission,
  permissions,
  requireAll = true,
  children,
  fallback = null,
}: CanProps) => {
  const { hasPermission, hasAllPermissions, hasAnyPermission } = usePermissions();

  let hasAccess = false;

  if (permission) {
    hasAccess = hasPermission(permission);
  } else if (permissions) {
    hasAccess = requireAll
      ? hasAllPermissions(permissions)
      : hasAnyPermission(permissions);
  }

  return hasAccess ? <>{children}</> : <>{fallback}</>;
};
```

**File**: `frontend/src/features/auth/hooks/usePermissions.ts`

```typescript
import { useAuth } from './useAuth';
import type { Permission } from '@/types/generated/api';

export const usePermissions = () => {
  const { user } = useAuth();

  const userPermissions = new Set(
    user?.roles?.flatMap((role) => role.permissions.map((p) => p.name)) || []
  );

  const hasPermission = (permission: Permission): boolean => {
    return userPermissions.has(permission);
  };

  const hasAllPermissions = (permissions: Permission[]): boolean => {
    return permissions.every((p) => userPermissions.has(p));
  };

  const hasAnyPermission = (permissions: Permission[]): boolean => {
    return permissions.some((p) => userPermissions.has(p));
  };

  return {
    hasPermission,
    hasAllPermissions,
    hasAnyPermission,
    permissions: Array.from(userPermissions),
  };
};
```

**Usage in Components**:

```typescript
import { Can } from '@/components/auth/Can';
import { Button } from '@/components/ui/button';

const UserActions = ({ userId }: { userId: string }) => {
  return (
    <div className="flex gap-2">
      <Can permission="USERS_WRITE">
        <Button onClick={() => handleEdit(userId)}>Edit</Button>
      </Can>

      <Can permission="USERS_DELETE">
        <Button variant="destructive" onClick={() => handleDelete(userId)}>
          Delete
        </Button>
      </Can>

      {/* Show message if user can't do anything */}
      <Can
        permissions={['USERS_WRITE', 'USERS_DELETE']}
        requireAll={false}
        fallback={<p className="text-muted-foreground">No actions available</p>}
      />
    </div>
  );
};
```

## Request/Response Patterns

### Pagination

**Backend**:
```python
from typing import Generic, TypeVar, List
from pydantic import BaseModel

T = TypeVar("T")

class PaginatedResponse(BaseModel, Generic[T]):
    items: List[T]
    total: int
    page: int
    size: int
    pages: int

@router.get("/users", response_model=PaginatedResponse[UserResponse])
async def list_users(
    page: int = 1,
    size: int = 10,
    sort: str = "created_at",
    order: str = "desc"
):
    # Calculate offset
    offset = (page - 1) * size

    # Query with pagination
    users = await user_repository.get_paginated(
        offset=offset,
        limit=size,
        sort_by=sort,
        order=order
    )

    total = await user_repository.count()

    return PaginatedResponse(
        items=users,
        total=total,
        page=page,
        size=size,
        pages=(total + size - 1) // size  # Ceiling division
    )
```

**Frontend**:
```typescript
import { useQuery } from '@tanstack/react-query';
import { getUsers } from '../api/users';

export const useUsers = (page = 1, size = 10) => {
  return useQuery({
    queryKey: ['users', { page, size }],
    queryFn: () => getUsers({ page, size }),
    // Keep previous data while fetching new page
    placeholderData: (prev) => prev,
  });
};

// Usage in component
const UserList = () => {
  const [page, setPage] = useState(1);
  const { data, isLoading } = useUsers(page);

  return (
    <div>
      {data?.items.map((user) => (
        <UserCard key={user.id} user={user} />
      ))}

      <Pagination
        currentPage={data?.page || 1}
        totalPages={data?.pages || 1}
        onPageChange={setPage}
      />
    </div>
  );
};
```

### Filtering & Search

**Backend**:
```python
@router.get("/users")
async def list_users(
    search: str | None = None,
    role: str | None = None,
    is_active: bool | None = None,
    page: int = 1,
    size: int = 10
):
    filters = {}

    if search:
        filters["search"] = search  # Search email or name
    if role:
        filters["role"] = role
    if is_active is not None:
        filters["is_active"] = is_active

    users = await user_repository.get_filtered(
        filters=filters,
        offset=(page - 1) * size,
        limit=size
    )

    return PaginatedResponse(...)
```

**Frontend**:
```typescript
export const useUsers = (filters: {
  search?: string;
  role?: string;
  isActive?: boolean;
  page?: number;
  size?: number;
}) => {
  return useQuery({
    queryKey: ['users', filters],
    queryFn: () => getUsers(filters),
  });
};

// Usage with form
const UserList = () => {
  const [filters, setFilters] = useState({
    search: '',
    role: '',
    page: 1,
  });

  const { data } = useUsers(filters);

  return (
    <div>
      <input
        value={filters.search}
        onChange={(e) => setFilters({ ...filters, search: e.target.value })}
        placeholder="Search users..."
      />

      {/* Results */}
    </div>
  );
};
```

### Bulk Operations

**Backend**:
```python
from pydantic import BaseModel
from typing import List

class BulkDeleteRequest(BaseModel):
    ids: List[UUID]

@router.post("/users/bulk-delete")
@require_permissions(Permission.USERS_DELETE)
async def bulk_delete_users(
    request: BulkDeleteRequest,
    current_user: User = Depends(get_current_user)
):
    deleted_count = await user_service.delete_many(request.ids)

    return {"deleted": deleted_count}
```

**Frontend**:
```typescript
export const useBulkDeleteUsers = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (ids: string[]) => bulkDeleteUsers(ids),
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      toast.success(`Deleted ${data.deleted} users`);
    },
  });
};

// Usage with selection
const UserList = () => {
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const bulkDelete = useBulkDeleteUsers();

  const handleBulkDelete = () => {
    bulkDelete.mutate(selectedIds);
    setSelectedIds([]);
  };

  return (
    <div>
      {/* Checkboxes for selection */}

      <Can permission="USERS_DELETE">
        <Button
          onClick={handleBulkDelete}
          disabled={selectedIds.length === 0}
        >
          Delete Selected ({selectedIds.length})
        </Button>
      </Can>
    </div>
  );
};
```

### File Upload

**Backend**:
```python
from fastapi import UploadFile, File

@router.post("/users/{user_id}/avatar")
@require_permissions(Permission.USERS_WRITE)
async def upload_avatar(
    user_id: UUID,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    # Validate file type
    if file.content_type not in ["image/jpeg", "image/png"]:
        raise ValidationException("Only JPEG and PNG images allowed")

    # Validate file size (max 5MB)
    contents = await file.read()
    if len(contents) > 5 * 1024 * 1024:
        raise ValidationException("File size must be less than 5MB")

    # Save file (use cloud storage in production)
    file_path = await storage_service.save_avatar(user_id, contents)

    # Update user record
    await user_service.update_avatar(user_id, file_path)

    return {"avatar_url": file_path}
```

**Frontend**:
```typescript
export const uploadAvatar = async (userId: string, file: File): Promise<{ avatar_url: string }> => {
  const formData = new FormData();
  formData.append('file', file);

  const { data } = await apiClient.post(`/users/${userId}/avatar`, formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });

  return data;
};

export const useUploadAvatar = (userId: string) => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (file: File) => uploadAvatar(userId, file),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users', userId] });
      toast.success('Avatar uploaded successfully');
    },
  });
};

// Usage in component
const AvatarUpload = ({ userId }: { userId: string }) => {
  const upload = useUploadAvatar(userId);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      upload.mutate(file);
    }
  };

  return (
    <div>
      <input
        type="file"
        accept="image/jpeg,image/png"
        onChange={handleFileChange}
        disabled={upload.isPending}
      />
      {upload.isPending && <p>Uploading...</p>}
    </div>
  );
};
```

## Next Steps

- **Need architecture details?** → See `docs/ARCHITECTURE.md`
- **Implementing a feature?** → See `docs/FULLSTACK_WORKFLOW.md`
- **Using Claude Code?** → See `CLAUDE_CODE_BEST_PRACTICES.md`
