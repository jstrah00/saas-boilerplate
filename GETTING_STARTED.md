# Getting Started

Quick start guide for new developers to set up and run the SaaS boilerplate locally.

## Prerequisites

Install these tools before starting:

- **Docker** (v24+) and **Docker Compose** (v2+) - [Install Docker](https://docs.docker.com/get-docker/)
- **Git** - [Install Git](https://git-scm.com/downloads)
- **Node.js** (v20+) and **npm** (v10+) - [Install Node.js](https://nodejs.org/)
- **Python** (v3.11+) - [Install Python](https://www.python.org/downloads/)

**Optional** (for development without Docker):
- **PostgreSQL** (v15+)
- **MongoDB** (v6+)

## Installation

### 1. Clone Repository

```bash
git clone <repository-url>
cd saas-boilerplate
```

### 2. Start Databases

```bash
# Start PostgreSQL and MongoDB in background
docker compose up -d postgres mongodb

# Verify databases are running
docker compose ps
```

### 3. Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Linux/Mac:
source venv/bin/activate
# On Windows:
# venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env

# Run migrations (creates tables)
alembic upgrade head

# Seed initial data (admin user, roles, permissions)
python -m app.db.seed

# Start backend server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Backend should now be running at**: http://localhost:8000

### 4. Frontend Setup

Open a **new terminal** (keep backend running):

```bash
cd frontend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Generate TypeScript types from backend
npm run generate:types

# Start frontend dev server
npm run dev
```

**Frontend should now be running at**: http://localhost:5173

## Login

Default credentials (created by seed script):

- **Email**: `admin@example.com`
- **Password**: `admin123`

**⚠️ Change these in production!**

## Verify Installation

### 1. Check Services

Open these URLs in your browser:

- **Frontend**: http://localhost:5173 (React app should load)
- **Backend API Docs**: http://localhost:8000/docs (Swagger UI)
- **Backend Health**: http://localhost:8000/api/v1/health (should return `{"status": "healthy"}`)

### 2. Test Login

1. Go to http://localhost:5173
2. Click "Login" (or navigate to `/login`)
3. Enter `admin@example.com` / `admin123`
4. Should redirect to dashboard

### 3. Test API

```bash
# Login to get access token
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin@example.com&password=admin123"

# Copy access_token from response

# Test authenticated endpoint
curl http://localhost:8000/api/v1/users/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 4. Check Database

```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U postgres -d saas_boilerplate

# List tables
\dt

# Check users table
SELECT id, email, is_active FROM users;

# Exit
\q
```

### 5. Access Development Tools (Optional)

```bash
# Start dev tools (pgAdmin, mongo-express)
docker compose --profile tools up -d

# Wait ~10 seconds for tools to initialize
```

**Access**:
- **pgAdmin** (PostgreSQL UI): http://localhost:5050
  - Login: `admin@admin.com` / `admin`
  - Add server: Host=`postgres`, Port=`5432`, User=`postgres`, Password=`postgres`

- **mongo-express** (MongoDB UI): http://localhost:8081
  - No login required (dev only!)

## Next Steps

### New to the Project?

1. **Read Core Documentation**:
   - `CLAUDE.md` - Root orchestration context
   - `backend/CLAUDE.md` - Backend architecture and patterns
   - `frontend/CLAUDE.md` - Frontend architecture and patterns

2. **Understand Architecture**:
   - `docs/ARCHITECTURE.md` - System design, database strategy, auth flow

3. **Learn Workflows**:
   - `docs/FULLSTACK_WORKFLOW.md` - How to implement features end-to-end

### Using Claude Code?

4. **Read Best Practices**:
   - `CLAUDE_CODE_BEST_PRACTICES.md` - ⭐ Comprehensive guide (model selection, plan mode, token management, workflows)

5. **Set Up Claude.ai Project** (Optional):
   - `docs/prompts/CLAUDE_PROJECT_SETUP.md` - For complex feature planning

### Ready to Build?

6. **Try Adding a Simple Feature**:
   ```
   Example: Add a "Notes" feature where users can create/read/update/delete notes

   Backend:
   - Use /fastapi-feature skill in Claude Code
   - Prompt: "Create complete backend for Notes (title, content, user_id)"

   Frontend:
   - Use /react-feature skill
   - Prompt: "Create frontend for Notes with list, form, and detail pages"
   ```

7. **Explore Skills**:
   - Backend: `/fastapi-endpoint`, `/fastapi-model`, `/fastapi-migration`, `/fastapi-test`
   - Frontend: `/react-component`, `/react-form`, `/api-integration`, `/react-page`

8. **Check Reference Implementations**:
   - Backend: `backend/app/api/v1/endpoints/users.py` (CRUD example)
   - Frontend: `frontend/src/features/auth/` (Complete feature structure)

## Common Issues

### Port Already in Use

**Error**: `Port 8000/5173 is already in use`

**Solution**:
```bash
# Find process using port
# On Linux/Mac:
lsof -i :8000
# On Windows:
# netstat -ano | findstr :8000

# Kill process or change port in .env
```

### Database Connection Failed

**Error**: `Connection to postgres:5432 refused`

**Solution**:
```bash
# Check databases are running
docker compose ps

# Restart databases
docker compose restart postgres mongodb

# Check logs
docker compose logs postgres
```

### Module Not Found (Backend)

**Error**: `ModuleNotFoundError: No module named 'app'`

**Solution**:
```bash
# Ensure virtual environment is activated
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

# Reinstall dependencies
pip install -r requirements.txt

# Run from backend/ directory
cd backend
uvicorn app.main:app --reload
```

### Type Generation Failed (Frontend)

**Error**: `Failed to generate types from OpenAPI`

**Solution**:
```bash
# Ensure backend is running
curl http://localhost:8000/docs

# Try manual generation
cd frontend
npm run generate:types

# Check backend OpenAPI endpoint
curl http://localhost:8000/openapi.json
```

### Login Failed

**Error**: `401 Unauthorized` on login

**Solution**:
```bash
# Check admin user exists
docker compose exec postgres psql -U postgres -d saas_boilerplate \
  -c "SELECT email, is_active FROM users WHERE email='admin@example.com';"

# Re-run seed script
cd backend
python -m app.db.seed

# Check backend logs for errors
docker compose logs backend
```

## Stopping Services

```bash
# Stop backend (Ctrl+C in backend terminal)

# Stop frontend (Ctrl+C in frontend terminal)

# Stop Docker services
docker compose down

# Stop and remove volumes (⚠️ deletes all data)
docker compose down -v
```

## Project Structure

```
saas-boilerplate/
├── backend/              # FastAPI backend
│   ├── app/
│   │   ├── api/          # REST endpoints
│   │   ├── models/       # SQLAlchemy models
│   │   ├── schemas/      # Pydantic schemas
│   │   ├── repositories/ # Database queries
│   │   ├── services/     # Business logic
│   │   └── common/       # Shared utilities
│   ├── tests/            # pytest tests
│   ├── alembic/          # Database migrations
│   └── requirements.txt
│
├── frontend/             # React frontend
│   ├── src/
│   │   ├── features/     # Feature modules
│   │   ├── components/   # Shared components
│   │   ├── lib/          # Utilities
│   │   ├── types/        # TypeScript types
│   │   └── routes/       # TanStack Router routes
│   └── package.json
│
├── docs/                 # Documentation
│   ├── ARCHITECTURE.md
│   ├── FULLSTACK_WORKFLOW.md
│   └── prompts/
│
├── docker-compose.yml    # Docker services
├── CLAUDE.md             # Root context for Claude Code
├── README.md             # Project overview
└── GETTING_STARTED.md    # This file
```

## Development Workflow

### Typical Feature Implementation

1. **Plan** (optional for complex features):
   - Use Claude.ai Project to design architecture
   - Generate implementation prompts

2. **Backend**:
   - Create models: `/fastapi-model`
   - Create migration: `/fastapi-migration`
   - Add permissions: `/fastapi-permission`
   - Create endpoints: `/fastapi-endpoint`
   - Write tests: `/fastapi-test`

3. **Generate Types**:
   ```bash
   cd frontend
   npm run generate:types
   ```

4. **Frontend**:
   - Create API integration: `/api-integration`
   - Create components: `/react-component`
   - Create forms: `/react-form`
   - Create pages: `/react-page`

5. **Test**:
   - Backend: `pytest backend/tests/`
   - Frontend: Manual testing in browser

6. **Commit**:
   ```bash
   git add .
   git commit -m "Add feature X

   - Backend: endpoints, models, tests
   - Frontend: components, pages, API integration

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   ```

**See**: `docs/FULLSTACK_WORKFLOW.md` for detailed workflows

## Support

- **Documentation**: See `README.md` for complete documentation map
- **Issues**: Check existing patterns in `backend/` and `frontend/` codebases
- **Claude Code Help**: Read `CLAUDE_CODE_BEST_PRACTICES.md`
- **Architecture Questions**: See `docs/ARCHITECTURE.md`

## What's Next?

You're all set! 🎉

- ✅ Services are running
- ✅ You can log in
- ✅ API and frontend are connected

**Recommended Next Steps**:
1. Read `CLAUDE.md` for project overview
2. Explore `docs/ARCHITECTURE.md` to understand system design
3. Try implementing a simple feature following `docs/FULLSTACK_WORKFLOW.md`
4. If using Claude Code, read `CLAUDE_CODE_BEST_PRACTICES.md` ⭐
