# Troubleshooting Guide

Common issues and solutions for the SaaS Boilerplate. If you encounter a problem not listed here, check:
- `frontend/TROUBLESHOOTING.md` for frontend-specific issues
- GitHub Issues for reported problems
- `GETTING_STARTED.md` for setup guidance

## Table of Contents

- [Setup & Installation](#setup--installation)
- [Docker & Containers](#docker--containers)
- [Database Issues](#database-issues)
- [Backend Issues](#backend-issues)
- [Frontend Issues](#frontend-issues)
- [Type Generation](#type-generation)
- [Authentication & Permissions](#authentication--permissions)
- [CORS Errors](#cors-errors)
- [Performance Issues](#performance-issues)

---

## Setup & Installation

### Issue: Submodules are Empty After Clone

**Symptoms**:
- `backend/` and `frontend/` directories exist but are empty
- No files inside submodule directories

**Cause**: Cloned without `--recurse-submodules` flag

**Solution**:
```bash
# Initialize and update submodules
git submodule init
git submodule update

# Verify submodules are populated
ls -la backend/
ls -la frontend/
```

**Prevention**: Always clone with:
```bash
git clone --recurse-submodules <repository-url>
```

---

### Issue: `docker-compose: command not found`

**Symptoms**:
```
docker-compose: command not found
```

**Cause**: Docker Compose V2 not installed or using old V1 syntax

**Solution 1** (Docker Compose V2 - Recommended):
```bash
# Check Docker version (should include Compose V2)
docker compose version

# If not found, update Docker Desktop
# Or install Docker Compose plugin
```

**Solution 2** (Use V1 if necessary):
```bash
# Install docker-compose V1
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Use with hyphen
docker-compose up -d
```

**Recommended**: Use Docker Compose V2 (`docker compose` without hyphen)

---

### Issue: Port Already in Use

**Symptoms**:
```
Error: bind: address already in use
Port 8000/5173/5432/27017 is already allocated
```

**Cause**: Another service is using the required port

**Solution**:
```bash
# Find process using port (Linux/Mac)
lsof -i :8000 # Backend
lsof -i :5173 # Frontend
lsof -i :5432 # PostgreSQL
lsof -i :27017 # MongoDB

# Kill process
kill -9 <PID>

# Windows: Find and kill process
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

**Alternative**: Change port in docker-compose.yml:
```yaml
services:
 backend:
 ports:
 - "8001:8000" # Map to different host port
```

---

### Issue: Python Version Mismatch

**Symptoms**:
```
Error: Python 3.11+ required
```

**Cause**: Wrong Python version installed

**Solution**:
```bash
# Check Python version
python --version
python3 --version

# Install Python 3.11+ (Mac with Homebrew)
brew install python@3.11

# Install Python 3.11+ (Ubuntu)
sudo apt update
sudo apt install python3.11

# Use pyenv for version management (recommended)
pyenv install 3.11.0
pyenv global 3.11.0
```

---

### Issue: UV Package Manager Not Found

**Symptoms**:
```
uv: command not found
```

**Cause**: UV not installed

**Solution**:
```bash
# Install UV (Mac/Linux)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install UV (Windows)
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# Verify installation
uv --version

# Add to PATH if needed
export PATH="$HOME/.cargo/bin:$PATH"
```

**Documentation**: https://docs.astral.sh/uv/

---

## Docker & Containers

### Issue: Services Won't Start

**Symptoms**:
```
Error: service "backend" didn't complete successfully: exit 1
```

**Diagnosis**:
```bash
# Check service logs
docker compose logs backend
docker compose logs postgres
docker compose logs mongodb

# Check container status
docker compose ps
```

**Common Causes**:
1. **Database not ready**: Backend starts before DB is healthy
2. **Environment variables**: Missing or incorrect .env values
3. **Port conflicts**: Ports already in use
4. **Volume permissions**: Permission denied on mounted volumes

**Solutions**:
```bash
# Restart services
docker compose restart backend

# Rebuild images
docker compose build --no-cache
docker compose up -d

# Remove and recreate
docker compose down
docker compose up -d

# Check environment variables
docker compose config
```

---

### Issue: Database Volumes Permission Denied

**Symptoms**:
```
Permission denied: '/var/lib/postgresql/data'
```

**Cause**: Volume ownership mismatch

**Solution**:
```bash
# Stop services
docker compose down

# Remove volumes (WARNING: deletes data!)
docker compose down -v

# Restart
docker compose up -d

# Or fix permissions (Linux)
sudo chown -R $(id -u):$(id -g) ./data
```

---

### Issue: Backend Container Keeps Restarting

**Symptoms**:
- Backend container constantly restarts
- `docker compose ps` shows "Restarting"

**Diagnosis**:
```bash
# View logs
docker compose logs backend --tail=50

# Common errors:
# - Module not found
# - Database connection failed
# - Port already in use inside container
```

**Solutions**:

**Problem**: Module not found
```bash
# Rebuild with dependencies
docker compose build --no-cache backend
docker compose up -d
```

**Problem**: Database connection
```bash
# Check DATABASE_URL in docker-compose.yml
# Ensure postgres service name matches connection string
# Wait for database health check
```

**Problem**: Migration failed
```bash
# Run migrations manually
docker compose exec backend alembic upgrade head
```

---

## Database Issues

### Issue: PostgreSQL Connection Refused

**Symptoms**:
```
psycopg2.OperationalError: could not connect to server: Connection refused
```

**Cause**: PostgreSQL not running or wrong connection details

**Solution**:
```bash
# Check if PostgreSQL is running
docker compose ps postgres

# Start if stopped
docker compose up -d postgres

# Wait for health check
docker compose logs postgres | grep "ready to accept"

# Test connection
docker compose exec postgres psql -U postgres -d saas_boilerplate

# Verify DATABASE_URL in backend/.env
# Should be: postgresql://postgres:postgres@postgres:5432/saas_boilerplate
# ^^^^^^^^ Use service name (postgres), not localhost!
```

**Common Mistakes**:
- Using `localhost` instead of `postgres` (service name)
- Wrong port (should be 5432)
- Wrong credentials

---

### Issue: MongoDB Connection Failed

**Symptoms**:
```
pymongo.errors.ServerSelectionTimeoutError: localhost:27017: [Errno 61] Connection refused
```

**Cause**: MongoDB not running or wrong connection string

**Solution**:
```bash
# Check if MongoDB is running
docker compose ps mongodb

# Start if stopped
docker compose up -d mongodb

# Test connection
docker compose exec mongodb mongosh -u admin -p admin

# Verify MONGODB_URL in backend/.env or docker-compose.yml
# Should be: mongodb://admin:admin@mongodb:27017/saas_boilerplate?authSource=admin
# ^^^^^^^ Use service name!
```

---

### Issue: Table Already Exists Error

**Symptoms**:
```
sqlalchemy.exc.ProgrammingError: (psycopg2.errors.DuplicateTable) relation "users" already exists
```

**Cause**: Trying to create table that already exists (migration issue)

**Solution**:
```bash
# Check current migration
cd backend
uv run alembic current

# Check pending migrations
uv run alembic heads

# Option 1: Mark current state (if tables manually created)
uv run alembic stamp head

# Option 2: Rollback and re-apply
uv run alembic downgrade -1
uv run alembic upgrade head

# Option 3: Reset database (WARNING: deletes data!)
docker compose down -v
docker compose up -d postgres
uv run alembic upgrade head
uv run python scripts/init_db.py
```

---

### Issue: Database Locked (SQLite in Tests)

**Symptoms**:
```
sqlite3.OperationalError: database is locked
```

**Cause**: Another process accessing test database

**Solution**:
```bash
# Kill any running test processes
pkill -f pytest

# Delete test database
rm backend/test.db

# Run tests again
pytest
```

---

## Backend Issues

### Issue: ModuleNotFoundError

**Symptoms**:
```
ModuleNotFoundError: No module named 'app'
```

**Cause**: Running from wrong directory or dependencies not installed

**Solution**:
```bash
# Ensure you're in backend/ directory
cd backend

# Install dependencies
uv sync

# Check if virtual environment active (with UV it's automatic)
which python

# Run with UV (ensures correct environment)
uv run dev

# Or use uvicorn directly
uv run uvicorn app.main:app --reload
```

---

### Issue: Alembic Migration Conflicts

**Symptoms**:
```
ERROR [alembic.util.messaging] Target database is not up to date.
Multiple heads found
```

**Cause**: Multiple migration branches (git conflicts or parallel development)

**Solution**:
```bash
# View migration history
uv run alembic history

# Identify conflicting heads
uv run alembic heads

# Option 1: Merge heads
uv run alembic merge -m "merge heads" <head1> <head2>
uv run alembic upgrade head

# Option 2: Reset migrations (WARNING: data loss!)
# Drop all tables
docker compose exec postgres psql -U postgres -d saas_boilerplate -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
# Re-run migrations
uv run alembic upgrade head
```

---

### Issue: Import Circular Dependency

**Symptoms**:
```
ImportError: cannot import name 'User' from partially initialized module 'app.models.user'
```

**Cause**: Circular import between models or modules

**Solution**:
```python
# Use TYPE_CHECKING to avoid runtime import
from typing import TYPE_CHECKING

if TYPE_CHECKING:
 from app.models.user import User

# Or use string reference in relationships
class Order(Base):
 user: Mapped["User"] = relationship("User", back_populates="orders")
```

---

### Issue: Pydantic Validation Error

**Symptoms**:
```
pydantic_core._pydantic_core.ValidationError: 1 validation error for UserResponse
```

**Cause**: Schema doesn't match model or missing `from_attributes = True`

**Solution**:
```python
# Ensure Response schemas have from_attributes
class UserResponse(BaseModel):
 model_config = ConfigDict(from_attributes=True) # ← Required for SQLAlchemy!

 id: UUID
 email: str
 # ... other fields
```

---

## Frontend Issues

### Issue: Cannot Find Module '@/...'

**Symptoms**:
```
Cannot find module '@/components/ui/button'
```

**Cause**: Path alias not configured or module doesn't exist

**Solution**:
```bash
# Check if file exists
ls frontend/src/components/ui/button.tsx

# Verify path alias in tsconfig.json
cat frontend/tsconfig.json | grep "@"
# Should have: "@/*": ["./src/*"]

# Restart dev server
cd frontend
npm run dev
```

---

### Issue: Type Errors After Backend Change

**Symptoms**:
```
Property 'newField' does not exist on type 'User'
```

**Cause**: Backend schema changed but frontend types not regenerated

**Solution**:
```bash
# Regenerate types
cd frontend
npm run generate:types

# Verify types generated
grep "newField" src/types/generated/api.ts

# If generation fails, check backend is running
curl http://localhost:8000/openapi.json
```

---

### Issue: Axios Request Failed with CORS

**Symptoms**:
```
Access to XMLHttpRequest at 'http://localhost:8000' from origin 'http://localhost:5173' has been blocked by CORS policy
```

**See**: [CORS Errors](#cors-errors) section

---

## Type Generation

### Issue: Type Generation Fails

**Symptoms**:
```
Error: Failed to fetch OpenAPI schema
Failed to generate types
```

**Cause**: Backend not running or OpenAPI endpoint unavailable

**Diagnosis**:
```bash
# Check backend is running
curl http://localhost:8000/api/v1/health

# Check OpenAPI endpoint
curl http://localhost:8000/openapi.json

# Check if OpenAPI route exists
curl http://localhost:8000/docs
```

**Solution**:
```bash
# Ensure backend is running
cd backend
uv run dev

# In new terminal, generate types
cd frontend
npm run generate:types

# If still fails, check package.json script
cat package.json | grep generate:types

# Manually run openapi-typescript-codegen
npx openapi-typescript-codegen --input http://localhost:8000/openapi.json --output ./src/types/generated
```

---

### Issue: Generated Types are Empty

**Symptoms**:
- `src/types/generated/api.ts` is empty or minimal
- Missing expected interfaces

**Cause**: Backend schemas not properly exported in OpenAPI

**Solution**:
```bash
# Check OpenAPI schema
curl http://localhost:8000/openapi.json | jq '.components.schemas'

# Ensure response_model set on endpoints
# Example:
@router.get("/users", response_model=list[UserResponse]) # ← This exports UserResponse type
```

---

### Issue: Types Don't Match Backend

**Symptoms**:
- TypeScript shows no errors but API calls fail
- Runtime errors about missing/wrong fields

**Cause**: Types out of sync with backend

**Solution**:
```bash
# Always regenerate after backend changes
cd frontend
npm run generate:types

# Add to pre-commit hook (optional)
echo "cd frontend && npm run generate:types" >> .git/hooks/pre-commit
```

**Best Practice**: Regenerate types as part of CI/CD pipeline

---

## Authentication & Permissions

### Issue: 401 Unauthorized on All Requests

**Symptoms**:
```
401 Unauthorized
{"detail": "Not authenticated"}
```

**Cause**: Token missing, expired, or invalid

**Diagnosis**:
```bash
# Check if token exists
localStorage.getItem('access_token') # In browser console

# Check token expiration
jwt.io → paste token → check "exp" claim

# Test login
curl -X POST http://localhost:8000/api/v1/auth/login \
 -H "Content-Type: application/json" \
 -d '{"email": "admin@example.com", "password": "admin123"}'
```

**Solution**:
```javascript
// Frontend should auto-refresh on 401
// Check interceptor in src/api/client.ts

// Manual refresh
const refreshToken = localStorage.getItem('refresh_token');
const response = await axios.post('/api/v1/auth/refresh', { refresh_token: refreshToken });
localStorage.setItem('access_token', response.data.access_token);
```

---

### Issue: 403 Forbidden (Permission Denied)

**Symptoms**:
```
403 Forbidden
{"detail": "Permission denied"}
```

**Cause**: User lacks required permission

**Diagnosis**:
```bash
# Check user permissions in database
docker compose exec postgres psql -U postgres -d saas_boilerplate
SELECT u.email, r.name as role, p.name as permission
FROM users u
JOIN roles r ON u.role_id = r.id
JOIN role_permissions rp ON r.id = rp.role_id
JOIN permissions p ON rp.permission_id = p.id
WHERE u.email = 'admin@example.com';

# Check endpoint permission requirement
# Look for @require_permissions(Permission.USERS_READ) in code
```

**Solution**:
```python
# Option 1: Add permission to user's role
INSERT INTO role_permissions (role_id, permission_id)
VALUES (
 (SELECT id FROM roles WHERE name = 'user'),
 (SELECT id FROM permissions WHERE name = 'users:read')
);

# Option 2: Change user's role
UPDATE users SET role_id = (SELECT id FROM roles WHERE name = 'admin')
WHERE email = 'user@example.com';
```

---

### Issue: Login Succeeds but No Token Returned

**Symptoms**:
- Login returns 200 OK
- But `access_token` is null or missing

**Cause**: Response format mismatch

**Solution**:
```python
# Ensure login endpoint returns correct format
@router.post("/login", response_model=TokenResponse)
async def login(...):
 return {
 "access_token": access_token,
 "refresh_token": refresh_token,
 "token_type": "bearer"
 }
```

---

## CORS Errors

### Issue: CORS Policy Blocking Requests

**Symptoms**:
```
Access-Control-Allow-Origin header is missing
CORS policy: No 'Access-Control-Allow-Origin' header
```

**Cause**: Backend CORS not configured for frontend origin

**Solution**:
```python
# backend/app/main.py
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
 CORSMiddleware,
 allow_origins=["http://localhost:5173"], # ← Add your frontend URL
 allow_credentials=True,
 allow_methods=["*"],
 allow_headers=["*"],
)

# Or use environment variable (recommended)
# backend/.env
BACKEND_CORS_ORIGINS='["http://localhost:5173","http://localhost:3000"]'

# backend/app/main.py
import os
import json

origins = json.loads(os.getenv("BACKEND_CORS_ORIGINS", '["*"]'))
app.add_middleware(CORSMiddleware, allow_origins=origins, ...)
```

**Production Warning**: Never use `"*"` in production!

---

### Issue: CORS Preflight Request Failed

**Symptoms**:
```
OPTIONS request failed
405 Method Not Allowed on OPTIONS
```

**Cause**: CORS middleware not properly configured

**Solution**:
```python
# Ensure CORS middleware is added BEFORE routes
app.add_middleware(
 CORSMiddleware,
 allow_methods=["*"], # ← Allow OPTIONS
 allow_headers=["*"], # ← Allow custom headers
 allow_credentials=True,
)
```

---

## Performance Issues

### Issue: Slow API Responses

**Symptoms**:
- Requests take > 1 second
- Frontend feels sluggish

**Diagnosis**:
```python
# Add logging to see query times
import time

@router.get("/users")
async def list_users():
 start = time.time()
 users = await service.get_users()
 print(f"Query took: {time.time() - start:.2f}s")
 return users
```

**Common Causes & Solutions**:

**Problem**: N+1 queries
```python
# Bad: N+1 query problem
users = await session.execute(select(User))
for user in users:
 orders = await session.execute(select(Order).where(Order.user_id == user.id))

# Good: Use joinedload
from sqlalchemy.orm import joinedload

users = await session.execute(
 select(User).options(joinedload(User.orders))
)
```

**Problem**: Missing indexes
```python
# Add index on frequently queried columns
class User(Base):
 email: Mapped[str] = mapped_column(String, index=True) # ← Add index
 created_at: Mapped[datetime] = mapped_column(DateTime, index=True)
```

**Problem**: Large result sets without pagination
```python
# Always paginate list endpoints
@router.get("/users")
async def list_users(page: int = 1, size: int = 10):
 offset = (page - 1) * size
 users = await session.execute(
 select(User).offset(offset).limit(size)
 )
```

---

### Issue: Frontend Slow to Load

**Symptoms**:
- Initial page load > 5 seconds
- Large bundle size

**Diagnosis**:
```bash
# Check bundle size
npm run build
cd dist && du -sh *

# Analyze bundle
npm install -D vite-plugin-bundle-analyzer
# Add to vite.config.ts
```

**Solutions**:
```typescript
// Lazy load routes
const ProductsPage = lazy(() => import('./features/products/pages/ProductListPage'));

// Code splitting by route
<Route path="/products" element={
 <Suspense fallback={<Loading />}>
 <ProductsPage />
 </Suspense>
} />
```

---

## Getting More Help

### Search Order

1. **This file** - Common issues
2. **Frontend TROUBLESHOOTING** - `frontend/TROUBLESHOOTING.md`
3. **Documentation** - `README.md`, `GETTING_STARTED.md`, `docs/`
4. **GitHub Issues** - Check existing issues
5. **Logs** - `docker compose logs`

### Reporting Issues

When reporting issues, include:

```
**Environment**:
- OS: macOS 13.0 / Ubuntu 22.04 / Windows 11
- Docker version: docker --version
- Node version: node --version
- Python version: python --version

**Issue**:
[Describe problem]

**Steps to Reproduce**:
1. git clone ...
2. docker compose up
3. Error appears

**Logs**:
```
[Paste relevant logs]
```

**Expected Behavior**:
[What should happen]

**Actual Behavior**:
[What actually happens]
```

### Useful Commands for Debugging

```bash
# Docker
docker compose ps # Check service status
docker compose logs -f backend # Follow logs
docker compose exec backend sh # Shell into container

# Database
docker compose exec postgres psql -U postgres -d saas_boilerplate
docker compose exec mongodb mongosh -u admin -p admin

# Backend
cd backend
uv run alembic current # Check migration
uv run python # Python REPL
uv run ipython # IPython REPL

# Frontend
cd frontend
npm run dev -- --debug # Debug mode
npm run build -- --debug # Build debug

# Network
docker network ls # List networks
docker network inspect saas-network # Inspect network
curl http://localhost:8000/api/v1/health # Test backend
```

---

**Last Updated**: 2026-02-05
