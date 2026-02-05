# SaaS Boilerplate

A production-ready fullstack SaaS boilerplate with FastAPI backend and React frontend, optimized for rapid development with Claude Code.

## Overview

This monorepo provides a complete foundation for building SaaS applications with:

- **Modern Stack**: FastAPI + React with TypeScript
- **Type Safety**: End-to-end type generation from OpenAPI schemas
- **Authentication**: JWT-based auth with role-based access control (RBAC)
- **Database Strategy**: PostgreSQL (relational) + MongoDB (flexible/logs)
- **Developer Experience**: Hot reload, auto-generated API docs, Claude Code skills
- **Production Ready**: Migrations, testing, containerization

## Features

### Backend (FastAPI)

- [X] **FastAPI** with async/await support
- [X] **PostgreSQL** with SQLAlchemy ORM (async)
- [X] **MongoDB** with Motor (async ODM)
- [X] **Alembic** database migrations
- [X] **JWT Authentication** (access + refresh tokens)
- [X] **RBAC** (roles & permissions)
- [X] **Repository Pattern** (clean architecture)
- [X] **Pydantic V2** validation
- [X] **pytest** testing framework
- [X] **OpenAPI/Swagger** auto-generated docs
- [X] **CORS** configuration
- [X] **Environment-based** config

### Frontend (React)

- [X] **React 18** with TypeScript
- [X] **Vite** for fast builds
- [X] **React Router v6** (routing)
- [X] **TanStack Query** (server state management)
- [X] **Zustand** (client state management)
- [X] **shadcn/ui** component library
- [X] **Tailwind CSS** utility-first styling
- [X] **react-hook-form** + **Zod** validation
- [X] **axios** with interceptors (auto token refresh)
- [X] **Type generation** from backend OpenAPI

### Integration

- [X] **Type-safe API** contracts (backend → frontend)
- [X] **Auto token refresh** on 401
- [X] **Permission checks** (backend enforces, frontend UX)
- [X] **Error handling** (backend exceptions → frontend toasts)
- [X] **Docker Compose** for local development
- [X] **Claude Code skills** (13 skills for rapid development)

## Quick Start

**Prerequisites**: Docker, Node.js 20+, Python 3.11+

```bash
# 1. Clone repository with submodules
git clone --recurse-submodules <repository-url>
cd saas-boilerplate

# If already cloned without submodules:
git submodule init
git submodule update

# 2. Start all services
docker compose up -d

# 3. Access applications
# Frontend: http://localhost:5173
# Backend API: http://localhost:8000/docs
```

### Default Credentials

[!] **SECURITY WARNING**: Change these immediately in production!

- **Email**: `admin@example.com`
- **Password**: `admin123`

**Production Security Checklist**:
- [ ] Change admin password via API or database
- [ ] Generate new SECRET_KEY: `python -c "import secrets; print(secrets.token_hex(32))"`
- [ ] Update BACKEND_CORS_ORIGINS in backend/.env
- [ ] Set ENVIRONMENT=production and DEBUG=false
- [ ] Use strong database passwords
- [ ] Enable HTTPS with valid SSL certificates

**Detailed setup**: See `docs/GETTING_STARTED.md`

## Documentation

### Quick Start & Setup

- **[docs/GETTING_STARTED.md](./docs/GETTING_STARTED.md)** - Installation, setup, first steps (145 lines)
- **[CLAUDE.md](./CLAUDE.md)** - Root orchestration context for Claude Code (150 lines)

### Architecture & Design

- **[docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)** - System architecture, database strategy, auth flow (220 lines)
- **[backend/CLAUDE.md](./backend/CLAUDE.md)** - Backend patterns and workflow (194 lines)
- **[frontend/CLAUDE.md](./frontend/CLAUDE.md)** - Frontend patterns and workflow (212 lines)

### Workflows & Implementation

- **[docs/FULLSTACK_WORKFLOW.md](./docs/FULLSTACK_WORKFLOW.md)** - End-to-end feature implementation (270 lines)
- **[backend/docs/FEATURE_WORKFLOW.md](./backend/docs/FEATURE_WORKFLOW.md)** - Backend feature workflow
- **[frontend/docs/FEATURE_WORKFLOW.md](./frontend/docs/FEATURE_WORKFLOW.md)** - Frontend feature workflow

### Code Patterns & Examples

- **[docs/prompts/integration-patterns.md](./docs/prompts/integration-patterns.md)** - API integration patterns with code (400 lines)
- **[backend/docs/prompts/backend-patterns.md](./backend/docs/prompts/backend-patterns.md)** - Backend code patterns
- **[frontend/docs/prompts/frontend-patterns.md](./frontend/docs/prompts/frontend-patterns.md)** - Frontend code patterns

### Claude Code Integration

- **[docs/CLAUDE_CODE_BEST_PRACTICES.md](./docs/CLAUDE_CODE_BEST_PRACTICES.md)** - Comprehensive guide (240 lines)
 - Model selection (Sonnet vs Opus)
 - Plan mode usage
 - Token management strategies
 - Workflows (two-stage, backend-first, debugging)
 - Skills reference
 - Checklists

- **[docs/prompts/CLAUDE_PROJECT_SETUP.md](./docs/prompts/CLAUDE_PROJECT_SETUP.md)** - Claude.ai Project setup for planning (180 lines)

## Project Structure

```
saas-boilerplate/
├── backend/ # FastAPI backend
│ ├── app/
│ │ ├── api/v1/endpoints/ # REST API routes
│ │ ├── models/ # SQLAlchemy models
│ │ ├── schemas/ # Pydantic schemas (validation)
│ │ ├── repositories/ # Database access layer
│ │ ├── services/ # Business logic layer
│ │ ├── common/ # Shared utilities (auth, deps, exceptions)
│ │ ├── core/ # Config, settings
│ │ └── db/ # Database setup, seed data
│ ├── tests/ # pytest tests
│ ├── alembic/ # Database migrations
│ ├── CLAUDE.md # Backend context
│ ├── docs/ # Backend documentation
│ └── requirements.txt # Python dependencies
│
├── frontend/ # React frontend
│ ├── src/
│ │ ├── features/ # Feature-based modules
│ │ │ ├── auth/ # Authentication feature
│ │ │ │ ├── api/ # API calls
│ │ │ │ ├── hooks/ # React Query hooks
│ │ │ │ ├── components/ # Feature components
│ │ │ │ └── pages/ # Feature pages
│ │ │ └── ... # Other features
│ │ ├── components/ # Shared components
│ │ ├── lib/ # Utilities (api-client, utils)
│ │ ├── types/ # TypeScript types
│ │ │ └── generated/ # Auto-generated from backend
│ │ ├── routes/ # TanStack Router routes
│ │ └── main.tsx # App entry point
│ ├── CLAUDE.md # Frontend context
│ ├── docs/ # Frontend documentation
│ └── package.json # Node dependencies
│
├── docs/ # Root documentation
│ ├── ARCHITECTURE.md
│ ├── FULLSTACK_WORKFLOW.md
│ └── prompts/
│ ├── integration-patterns.md
│ └── CLAUDE_PROJECT_SETUP.md
│
├── .claude/ # Claude Code configuration
│ └── settings.json # Skills configuration
│
├── docker-compose.yml # Docker services
├── CLAUDE.md # Root context for Claude Code 
├── CLAUDE_CODE_BEST_PRACTICES.md # Comprehensive Claude Code guide 
├── GETTING_STARTED.md # Setup guide
└── README.md # This file
```

## Technology Stack

### Backend

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Framework | FastAPI 0.100+ | Async web framework |
| Language | Python 3.11+ | Type hints, async/await |
| Relational DB | PostgreSQL 15+ | Users, roles, transactional data |
| Document DB | MongoDB 6+ | Logs, events, flexible schemas |
| ORM | SQLAlchemy 2.0+ (async) | PostgreSQL queries |
| ODM | Motor | MongoDB async driver |
| Migrations | Alembic | Database version control |
| Validation | Pydantic V2 | Request/response validation |
| Testing | pytest + pytest-asyncio | Unit & integration tests |
| Auth | python-jose + passlib | JWT tokens, password hashing |
| API Docs | OpenAPI 3.0 | Auto-generated Swagger UI |

### Frontend

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Framework | React 18+ | UI library |
| Language | TypeScript 5+ | Type safety |
| Build Tool | Vite 5+ | Fast builds, HMR |
| Routing | React Router v6 | Declarative routing |
| Server State | TanStack Query | Caching, fetching, mutations |
| Client State | Zustand | Lightweight state management |
| Forms | react-hook-form + Zod | Form handling, validation |
| UI Library | shadcn/ui | Headless components |
| Styling | Tailwind CSS | Utility-first CSS |
| HTTP Client | axios | API calls with interceptors |
| Type Gen | openapi-typescript-codegen | Backend → TypeScript types |

### Infrastructure

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Containerization | Docker + Docker Compose | Local development environment |
| Database UI | pgAdmin, mongo-express | Database management tools |
| Reverse Proxy | Nginx/Caddy (production) | HTTPS, load balancing |

## Development

### Backend Development

```bash
cd backend

# Install dependencies
uv sync

# Run migrations
uv run alembic upgrade head

# Create migration after model changes
uv run alembic revision --autogenerate -m "description"

# Run tests
uv run pytest

# Run development server with hot reload
uv run dev

# Format code
uv run black .
uv run isort .

# Lint
uv run flake8 .
```

**See**: `backend/CLAUDE.md` for detailed workflow

### Frontend Development

```bash
cd frontend

# Install dependencies
npm install

# Generate types from backend
npm run generate:types

# Run dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Lint
npm run lint

# Format
npm run format
```

**See**: `frontend/CLAUDE.md` for detailed workflow

### Docker Compose

```bash
# Start all services
docker compose up -d

# Start with development tools (pgAdmin, mongo-express)
docker compose --profile tools up -d

# View logs
docker compose logs -f [backend|frontend|postgres|mongodb]

# Restart service
docker compose restart backend

# Stop all services
docker compose down

# Stop and remove volumes ([!] deletes data)
docker compose down -v

# Execute commands in containers
docker compose exec backend alembic upgrade head
docker compose exec postgres psql -U postgres -d saas_boilerplate
```

### Database Access

**PostgreSQL**:
```bash
# Via Docker
docker compose exec postgres psql -U postgres -d saas_boilerplate

# Via pgAdmin (with tools profile)
# http://localhost:5050 (admin@admin.com / admin)
```

**MongoDB**:
```bash
# Via Docker
docker compose exec mongodb mongosh

# Via mongo-express (with tools profile)
# http://localhost:8081
```

## Development Tools

### API Documentation

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

### Database Management

Start tools profile:
```bash
docker compose --profile tools up -d
```

- **pgAdmin** (PostgreSQL): http://localhost:5050
 - Login: `admin@admin.com` / `admin`
 - Add server: Host=`postgres`, Port=`5432`, Database=`saas_boilerplate`, User=`postgres`, Password=`postgres`

- **mongo-express** (MongoDB): http://localhost:8081
 - No login required (dev environment only)

### Health Check

```bash
# Backend health
curl http://localhost:8000/api/v1/health

# Expected: {"status":"healthy"}
```

## Claude Code Integration

This boilerplate is optimized for development with Claude Code via skills and comprehensive documentation.

### Available Skills

**Backend** (5 skills):
- `/fastapi-endpoint` - Complete CRUD with all layers
- `/fastapi-model` - SQLAlchemy models
- `/fastapi-migration` - Alembic migrations
- `/fastapi-permission` - Add permissions to RBAC
- `/fastapi-test` - pytest tests

**Frontend** (5 skills):
- `/react-component` - TypeScript components with shadcn/ui
- `/react-form` - Zod + react-hook-form validation
- `/api-integration` - API + TanStack Query hooks
- `/react-feature` - Complete frontend feature
- `/react-page` - Page with routing

**Root** (5 skills):
- **Active:**
 - `/backend-first` - Backend-first fullstack workflow
 - `/api-to-ui` - Frontend UI for existing backend APIs
 - `/fullstack-feature` - Complete E2E feature
- **Planned:**
 - `/api-contract` - Type-safe API contracts
 - `/deploy` - Deployment automation

### Quick Example

```bash
# Start Claude Code
claude-code

# Use a skill
/fastapi-endpoint

# Prompt: "Create CRUD endpoints for Products with name, price, sku"
# Claude generates: schema, repository, service, router, tests

# Generate types for frontend
cd frontend && npm run generate:types

# Create frontend integration
/api-integration

# Prompt: "Create Product API integration with TanStack Query hooks"
# Claude generates: API functions, useQuery hooks, useMutation hooks
```

### Documentation for Claude

**Essential Reading** (for effective Claude Code usage):

1. **[CLAUDE_CODE_BEST_PRACTICES.md](./CLAUDE_CODE_BEST_PRACTICES.md)**
 - Comprehensive A-I guide covering:
 - Model selection (Sonnet vs Opus)
 - Plan mode (when/how to use)
 - Token management (optimization strategies)
 - Workflows (two-stage, backend-first, debugging)
 - Skills reference
 - Conversation management
 - Checklists

2. **[CLAUDE.md](./CLAUDE.md)**
 - Root orchestration context
 - Integration patterns quick reference
 - Development workflows
 - Critical gotchas

3. **[docs/prompts/CLAUDE_PROJECT_SETUP.md](./docs/prompts/CLAUDE_PROJECT_SETUP.md)**
 - Set up Claude.ai Project for planning
 - Two-stage workflow (Project → Code)

**See**: `CLAUDE.md` for complete documentation map

## Contributing

### Code Style

**Backend**:
- Use `black` for formatting
- Use `isort` for import sorting
- Follow `flake8` rules
- Use type hints everywhere
- Write docstrings for public functions

**Frontend**:
- Use Prettier for formatting
- Follow ESLint rules
- Use TypeScript (no `any` types)
- Use functional components with hooks
- Follow feature-based architecture

### Commit Messages

```bash
# Format
<type>: <subject>

<body>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>

# Types: feat, fix, docs, refactor, test, chore

# Example
feat: Add product catalog feature

- Backend: Product and Category models with CRUD endpoints
- Permissions: PRODUCTS_READ, PRODUCTS_WRITE, PRODUCTS_DELETE
- Frontend: Product list, form, and detail pages
- Tests: Backend unit and integration tests

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### Pull Request Process

1. Create feature branch: `git checkout -b feature/product-catalog`
2. Implement feature following workflows in `docs/FULLSTACK_WORKFLOW.md`
3. Write tests (backend) and verify manually (frontend)
4. Ensure types generated: `cd frontend && npm run generate:types`
5. Commit with descriptive message
6. Push and create pull request
7. Ensure CI passes (tests, linting)
8. Request review

## License

MIT License - See [LICENSE](./LICENSE) file for details

## Support

### Documentation

- **Getting Started**: `docs/GETTING_STARTED.md`
- **Architecture**: `docs/ARCHITECTURE.md`
- **Workflows**: `docs/FULLSTACK_WORKFLOW.md`
- **Claude Code**: `docs/CLAUDE_CODE_BEST_PRACTICES.md`
- **Patterns**: `docs/prompts/integration-patterns.md`

### Common Tasks

- **Add new feature**: See `docs/FULLSTACK_WORKFLOW.md`
- **Add database model**: Use `/fastapi-model` skill
- **Add API endpoint**: Use `/fastapi-endpoint` skill
- **Add React component**: Use `/react-component` skill
- **Add new page**: Use `/react-page` skill
- **Debug issues**: See `docs/CLAUDE_CODE_BEST_PRACTICES.md` Section F

### Issues & Questions

- Check existing patterns in codebase
- Search documentation
- Review reference implementations:
 - Backend: `backend/app/api/v1/endpoints/users.py`
 - Frontend: `frontend/src/features/auth/`

## Roadmap

- [ ] WebSocket support for real-time features
- [ ] Email service integration
- [ ] File upload to S3/CloudFront
- [ ] Background job processing (Celery/Redis)
- [ ] Multi-tenancy (organizations)
- [ ] Admin dashboard
- [ ] API rate limiting
- [ ] Deployment guides (Docker, AWS, Vercel)
- [ ] CI/CD pipelines (GitHub Actions)
- [ ] Production monitoring (Sentry, DataDog)
- [ ] Implement planned fullstack skills

## Acknowledgments

Built with:
- [FastAPI](https://fastapi.tiangolo.com/)
- [React](https://react.dev/)
- [TanStack Query](https://tanstack.com/query)
- [TanStack Router](https://tanstack.com/router)
- [shadcn/ui](https://ui.shadcn.com/)
- [Tailwind CSS](https://tailwindcss.com/)
- [SQLAlchemy](https://www.sqlalchemy.org/)
- [Alembic](https://alembic.sqlalchemy.org/)
- [Pydantic](https://docs.pydantic.dev/)

Optimized for [Claude Code](https://claude.com/claude-code) development workflow.

---

**Ready to build?** Start with `docs/GETTING_STARTED.md`
