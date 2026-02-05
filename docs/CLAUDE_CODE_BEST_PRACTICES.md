# Claude Code Best Practices

Comprehensive guide to using Claude Code effectively with this boilerplate, covering model selection, plan mode, token management, workflows, and integration strategies.

## A. Model Selection

### Available Models

- **Sonnet 4.5** (Default) - Fast, cost-effective, excellent for most tasks
- **Opus 4.5** - Most capable, slower, use for complex problems

### When to Use Each

**Use Sonnet (Default) for**:
- [X] Implementing features from clear requirements
- [X] Writing CRUD endpoints, forms, components
- [X] Following established patterns in the boilerplate
- [X] Refactoring with clear goals
- [X] Writing tests
- [X] Documentation updates
- [X] Bug fixes with clear reproduction steps

**Use Opus for**:
- [X] Complex architectural decisions
- [X] Debugging obscure issues without clear cause
- [X] Designing new patterns not in boilerplate
- [X] Multi-system integration (3+ services)
- [X] Performance optimization (requires deep analysis)
- [X] Security reviews
- [X] Migrating between major framework versions

### Switching Models

**In Claude Code CLI**:
```bash
# Start with Sonnet (default)
claude-code

# Start with Opus
claude-code --model opus

# Switch mid-session (if available via settings)
# Use /model opus in chat
```

**Decision Tree**:
```
Choose OPUS if the task involves:
├─ Modifying 3+ services/systems → Opus
├─ Architectural decisions (patterns, structure) → Opus
├─ Debugging without clear cause → Opus
├─ Novel problems (no existing pattern) → Opus
└─ Otherwise → Sonnet
 ├─ Following existing patterns → Sonnet
 ├─ Standard CRUD/forms → Sonnet
 ├─ Clear bug fixes → Sonnet
 └─ Is Sonnet struggling after 2-3 attempts?
 └─ Yes → Switch to Opus
```

## B. Plan Mode

### What is Plan Mode?

Plan Mode lets Claude explore your codebase, design an implementation approach, and get your approval **before** writing code. This prevents wasted effort and token usage.

### When to Use Plan Mode

**Plan Mode is MANDATORY for**:
- [X] New features affecting 3+ files (non-negotiable)
- [X] Architectural changes (new patterns, refactoring)
- [X] Features with multiple valid approaches
- [X] When you're unsure of the best approach
- [X] Complex business logic requiring design review

**Skip Plan Mode ONLY for**:
- [X] Single-file changes (typos, small tweaks)
- [X] Following existing patterns with clear requirements
- [X] Clear, specific instructions ("Fix bug on line 42")
- [X] Simple component additions (1-2 files max)

### How to Use Plan Mode

**1. Trigger Plan Mode**:
```
User: "Add a multi-tenant organization feature where users can create orgs, invite members, and assign roles"

Claude: "This requires planning. Let me enter Plan Mode to design the implementation."
[Enters Plan Mode]
```

**2. Claude explores and plans**:
- Reads relevant files (models, schemas, existing patterns)
- Designs database schema
- Plans API endpoints
- Designs frontend components
- Identifies potential issues

**3. Review the plan**:
```
Claude: "Here's the implementation plan:

## Database Changes
- Organization model (id, name, slug, created_by)
- OrganizationMember junction table
- Migration: add org_id to existing tables

## Backend
- 6 new endpoints for org CRUD + member management
- 3 new permissions: ORGS_WRITE, ORGS_INVITE, ORGS_DELETE
- Update user schema to include organizations

## Frontend
- OrgSwitcher component in nav
- OrgSettings page
- MemberInviteForm
- Update 4 existing pages to filter by current org

Ready to implement? Any changes needed?"
```

**4. Approve or modify**:
```
User: "Looks good, but let's use 'workspace' instead of 'organization' for branding"

Claude: [Updates plan]

User: "Approved, implement it"

Claude: [Exits Plan Mode, implements according to plan]
```

### Plan Mode Benefits

- [X] **Prevents rework** - Catch design issues before implementation
- [X] **Saves tokens** - No back-and-forth after implementation
- [X] **Better architecture** - Time to consider trade-offs
- [X] **Alignment** - You approve the approach upfront
- [X] **Documentation** - Plan becomes implementation guide

### Plan Review Checklist

When reviewing a plan, check:
- [ ] Database schema makes sense (types, relationships, indexes)
- [ ] Permissions are granular enough (not too broad)
- [ ] API endpoints follow REST conventions
- [ ] Frontend components match design system
- [ ] No major files will be rewritten (prefer edits)
- [ ] Migration strategy is safe (no data loss)
- [ ] Tests are included in plan

## C. Token Management

### Pro Plan Limits

- **Token Budget**:
 - Per conversation: ~200K tokens maximum
 - Monthly limit (Pro plan): ~500K tokens total
 - Strategy: Use 2-3 conversations per feature to stay within monthly budget
- **Context Window**: Unlimited via auto-summarization
- **Usage**: Visible in UI during session

### Token Costs by Operation

**High Cost (1000-5000 tokens)**:
- Reading large files (>500 lines)
- Searching entire codebase without filters
- Generating comprehensive tests
- Writing detailed documentation

**Medium Cost (200-1000 tokens)**:
- Reading medium files (100-500 lines)
- Implementing CRUD endpoints
- Creating components with forms
- Refactoring functions

**Low Cost (<200 tokens)**:
- Reading small files (<100 lines)
- Simple edits
- Asking questions with references
- Using skills (pre-optimized)

### Token Optimization Strategies

**1. Use References Instead of Repeating**:
```
[-] Bad: "The backend uses FastAPI with SQLAlchemy ORM and has a repository pattern
 where repositories handle database queries and services handle business logic..."

[X] Good: "See backend/CLAUDE.md for architecture. I need a Product endpoint following
 the User endpoint pattern."
```

**2. Use Skills (Pre-Optimized Prompts)**:
```
[-] Bad: "Create a FastAPI endpoint for products with GET, POST, PUT, DELETE methods.
 It should have a schema, repository, service, and router. Follow the project
 structure and use permissions..."

[X] Good: /fastapi-endpoint
 "Create CRUD endpoints for Product"
```

**3. Start New Sessions for Unrelated Work**:
```
Session 1: Implement user authentication (stays focused)
[Complete and commit]

Session 2: Add product catalog (fresh context)
[Don't continue in Session 1 - avoid context bloat]
```

**4. Use Plan Mode to Avoid Rework**:
```
Without Plan Mode:
- Implement feature (5K tokens)
- "Oh, we need to change the approach" (2K tokens)
- Refactor (4K tokens)
Total: 11K tokens

With Plan Mode:
- Plan and review (2K tokens)
- Implement correctly first time (5K tokens)
Total: 7K tokens (36% savings)
```

**5. Be Specific with File References**:
```
[-] Bad: "Look at the user code and implement products the same way"
 [Claude searches, reads multiple files]

[X] Good: "Follow the pattern in backend/app/api/v1/endpoints/users.py:15-45"
 [Claude reads specific lines]
```

**6. Use Grep/Glob Effectively**:
```
[-] Bad: [Reads all files in features/]

[X] Good: [Greps for specific pattern: "useAuth"]
```

### Monitoring Token Usage

**During Session**:
- Check token counter in UI
- If nearing limit, consider wrapping up and starting new session

**After Session**:
- Review token usage in history
- Identify inefficient prompts for future improvement

## D. Workflows

### Two-Stage Workflow (Planning + Implementation)

**Best for**: Complex features, architectural changes, unclear requirements

**Stage 1: Claude.ai Project (Planning)**
```
1. Open Claude.ai → Select Project with boilerplate knowledge
2. Describe feature in detail
3. Claude analyzes patterns, designs solution
4. Claude outputs detailed implementation prompts
5. Review and approve plan
```

**Stage 2: Claude Code (Implementation)**
```
1. Start Claude Code session
2. Paste implementation prompts from Project
3. Claude executes prompts (already optimized)
4. Review and commit
```

**Example**:
```
[In Claude.ai Project]
User: "Design a notifications system with real-time updates via WebSockets,
 email digest options, and notification preferences per user"

Claude Project:
"Here's the architecture... [detailed design]

Implementation Prompts for Claude Code:

Prompt 1 (Backend Models):
'Create Notification model with fields: id, user_id, type, title, message,
 is_read, created_at. Create NotificationPreferences model with user_id, email_enabled,
 push_enabled, digest_frequency. Add migration.'

Prompt 2 (Backend WebSocket):
'Add WebSocket endpoint at /ws/notifications/{user_id}. Send new notifications
 to connected clients. Handle connection lifecycle.'

Prompt 3 (Frontend):
'Create NotificationBell component with unread count badge. Add NotificationList
 with real-time updates via WebSocket. Add NotificationPreferences form.'

..."

[Copy to Claude Code and execute]
```

**Benefits**:
- [X] Better planning in Project (unlimited context)
- [X] Faster implementation in Code (no re-planning)
- [X] Token-efficient (prompts pre-optimized)

**Setup**: See `docs/prompts/CLAUDE_PROJECT_SETUP.md`

### Direct Workflow (Single-Stage)

**Best for**: Small features, bug fixes, following established patterns

```
1. Start Claude Code
2. Describe task directly
3. Claude implements (uses Plan Mode if needed)
4. Review and commit
```

**Example**:
```
User: "Add a 'last_login' timestamp to User model and show it in the user profile"

Claude: [Reads User model, updates it, creates migration, updates frontend]
```

### Backend-First Workflow

**Best for**: Data-driven features, new resources, API-first development

```
1. Define models & migrations
 /fastapi-model → "Create Product model with..."
 /fastapi-migration → "Create migration for Product"

2. Add permissions
 /fastapi-permission → "Add PRODUCTS_READ, PRODUCTS_WRITE, PRODUCTS_DELETE"

3. Create API endpoints
 /fastapi-endpoint → "Create CRUD for Product"

4. Write tests
 /fastapi-test → "Test Product endpoints"

5. Generate frontend types
 cd frontend && npm run generate:types

6. Create frontend integration
 /api-integration → "Create Product API hooks"

7. Build UI
 /react-form → "Create ProductForm"
 /react-page → "Create ProductsPage"
```

**See**: `docs/FULLSTACK_WORKFLOW.md` for details

### Frontend-First Workflow

**Best for**: UI prototyping, design-heavy features, unclear backend needs

```
1. Create mock data
 const mockProducts = [...]

2. Build components
 /react-component → "Create ProductCard"
 /react-form → "Create ProductForm"

3. Test UX flows with mocks

4. Define backend contract
 [Document needed API based on frontend usage]

5. Implement backend
 [Follow Backend-First steps]

6. Replace mocks with real API
 /api-integration → "Connect ProductForm to API"
```

### Refactoring Workflow

**Best for**: Code cleanup, pattern changes, performance optimization

```
1. Use Plan Mode
 "I want to refactor the auth system to use httpOnly cookies instead of localStorage"

2. Claude creates refactoring plan:
 - Backend: Add cookie-based auth middleware
 - Frontend: Remove localStorage usage
 - Frontend: Update axios interceptor
 - Testing: Verify auth flow still works

3. Review plan for potential issues:
 - [ ] Are existing users migrated?
 - [ ] Is logout flow updated?
 - [ ] Are all token references removed?

4. Approve and implement

5. Test thoroughly before committing
```

### Debugging Workflow

**Best for**: Fixing bugs, resolving errors, investigating issues

```
1. Provide clear context:
 [-] "Login is broken"
 [X] "Login returns 401 even with correct credentials. Backend logs show
 'Invalid token signature'. Started after upgrading pyjwt library."

2. Share relevant info:
 - Error messages (full stack trace)
 - Recent changes (git diff)
 - Steps to reproduce
 - Expected vs actual behavior

3. Let Claude investigate:
 - Reads relevant files
 - Searches for similar patterns
 - Identifies root cause

4. If stuck, switch to Opus:
 "This is complex, let me use Opus for deeper analysis"

5. Apply fix and verify
```

## E. Skills

### Backend Skills (6)

**fastapi-endpoint** - Complete CRUD with all layers
```
Use: "Create CRUD endpoints for Product with permissions"
Generates: schema, repository, service, router
Time: ~2 min
```

**fastapi-model** - SQLAlchemy models
```
Use: "Create Product model with name, price, sku fields"
Generates: Model with proper types, relationships, indexes
Time: ~1 min
```

**fastapi-migration** - Alembic migrations
```
Use: "Create migration for Product model changes"
Generates: Migration file, handles up/down migrations
Time: ~1 min
```

**fastapi-permission** - RBAC permissions
```
Use: "Add PRODUCTS_WRITE and PRODUCTS_DELETE permissions"
Generates: Permission enum update, migration for new permissions
Time: ~1 min
```

**fastapi-test** - pytest tests
```
Use: "Create tests for Product endpoints"
Generates: Unit and integration tests, fixtures, assertions
Time: ~2 min
```

**fastapi-feature** - Complete backend feature
```
Use: "Create complete backend for Product catalog"
Generates: Models, migrations, permissions, endpoints, tests
Time: ~5 min
```

### Frontend Skills (5)

**react-component** - TypeScript components
```
Use: "Create ProductCard component with name, price, stock badge"
Generates: Component with TypeScript, Tailwind, shadcn/ui
Time: ~1 min
```

**react-form** - Zod + react-hook-form
```
Use: "Create ProductForm with validation"
Generates: Zod schema, form component, error handling
Time: ~2 min
```

**api-integration** - API + TanStack Query
```
Use: "Create Product API integration with hooks"
Generates: API functions, useQuery hooks, useMutation hooks
Time: ~2 min
```

**react-feature** - Complete frontend feature
```
Use: "Create complete Product feature"
Generates: API, hooks, forms, components, pages, routing
Time: ~5 min
```

**react-page** - Page with routing
```
Use: "Create ProductsPage at /products"
Generates: Page component, adds route, handles navigation
Time: ~1 min
```

### Root Skills

[!] **Note**: Skills marked as **(PLANNED)** are not yet available. Only invoke skills marked as **(ACTIVE)**.

**backend-first** - Backend-first workflow (ACTIVE)
```
Use: "Implement Product feature using backend-first workflow"
Generates: Complete backend (models, migrations, endpoints, tests) + frontend integration
Time: ~10 min
```

**api-to-ui** - API to UI integration (ACTIVE)
```
Use: "Create frontend UI for existing Product endpoints"
Generates: API client, React Query hooks, components, forms, pages
Time: ~5 min
```

**fullstack-feature** - Complete E2E feature (ACTIVE)
```
Use: "Create complete Product catalog (backend + frontend)"
Generates: Database models, API, frontend UI, routing, permissions
Time: ~15 min
```

**api-contract** - Type-safe API contracts (PLANNED)
```
Use: "Ensure Product API contract matches frontend usage"
Status: Planned - not yet available
```

**deploy** - Deployment automation (PLANNED)
```
Use: "Deploy to production"
Status: Planned - not yet available
```

### When to Use Skills vs Manual Prompts

**Use Skills**:
- [X] Following established patterns
- [X] Quick iteration needed
- [X] Want consistency across codebase
- [X] Token efficiency important

**Use Manual Prompts**:
- [X] Custom requirements not in patterns
- [X] Exploring new approaches
- [X] One-off unusual tasks
- [X] Need to explain complex context

## F. Debugging

### Provide Rich Context

**Minimal Context (Bad)**:
```
"Fix the login bug"
```

**Rich Context (Good)**:
```
"Login fails with 401 error. Details:

Error: POST /api/v1/auth/login returns 401 Unauthorized
Message: 'Invalid credentials'

Backend logs:
INFO: POST /api/v1/auth/login 401
ERROR: Password verification failed for user@example.com

Frontend code (src/features/auth/api/auth.ts:12-20):
[paste relevant code]

Steps to reproduce:
1. Enter email: user@example.com
2. Enter password: correct_password
3. Click Login
4. Get 401 error

Expected: Login successful, redirect to dashboard
Actual: Error toast 'Invalid credentials'

Recent changes:
- Upgraded bcrypt library yesterday
- Changed password hashing rounds in config

What I've tried:
- Verified user exists in database
- Checked password is correct
- Tested with new user registration (same issue)"
```

### Use Opus for Deep Debugging

**When Sonnet is Stuck**:
```
Sonnet (after 3 attempts): "I've tried X, Y, Z but the issue persists..."

User: "Let's switch to Opus for this"

[Start new session with Opus]

Opus: "Let me analyze this comprehensively..."
[Deeper investigation, finds root cause]
```

### Provide Minimal Reproduction

**Instead of Entire Codebase**:
```
[-] "The app is slow, investigate"

[X] "User list page takes 5+ seconds to load. Minimal repro:

Backend endpoint (users.py:45):
```python
@router.get("/users")
async def list_users(page: int = 1):
 # This query is slow
 users = await session.execute(
 select(User).options(selectinload(User.roles))
 )
 return users.scalars().all()
```

Frontend (UserList.tsx:20):
```typescript
const { data } = useQuery({
 queryKey: ['users'],
 queryFn: getUsers
});
```

Database has 50K users. Query takes 5s.
Expected: <1s with pagination."
```

### Share Logs and Errors

**Full Stack Traces**:
```
Don't truncate errors:

[-] "Error: ... [truncated]"

[X] "Full error:
Traceback (most recent call last):
 File "/app/main.py", line 45, in get_user
 user = await session.get(User, user_id)
 File "/usr/local/lib/python3.11/site-packages/sqlalchemy/...", line 234
 ...
sqlalchemy.exc.NoResultFound: No row was found when one was required"
```

## G. Conversation Management

### Session Hygiene

**One Feature Per Session**:
```
[X] Good:
Session 1: Implement Product catalog
Session 2: Add order management
Session 3: Fix login bug

[-] Bad:
Session 1: Products + Orders + Login + Deploy + Refactor auth
[Context becomes bloated, harder to follow]
```

**When to Start New Session**:
- [X] Completed and committed a feature
- [X] Switching to unrelated task
- [X] Token usage approaching limit
- [X] Session became unfocused
- [X] Need different model (Sonnet → Opus)

### Context Boundaries

**Reference Previous Work**:
```
Session 1: [Implements auth]
[Commit]

Session 2:
User: "Add password reset. Follow the auth pattern from previous session."
Claude: [Can access previous context via summarization]
```

**Don't Assume Context**:
```
[-] "Continue where we left off yesterday"
 [Claude doesn't remember yesterday's uncommitted work]

[X] "We implemented Product endpoints yesterday (see commit abc123).
 Now add category filtering."
```

### Effective Commits

**Commit Frequently**:
```
[X] After each feature
[X] After fixing a bug
[X] Before switching tasks
[X] Before ending session

Benefits:
- Claude can reference committed work
- Easy to rollback if needed
- Clear checkpoint for new sessions
```

## H. Claude.ai Project Integration

### Why Use Both?

**Claude.ai Project** = Planning & Architecture
- Unlimited context via knowledge files
- Upload entire docs/ folder
- Better for strategic thinking
- Generates implementation prompts

**Claude Code** = Execution & Implementation
- Writes actual code
- Runs tests
- Creates commits
- Fast iteration

### Setup

**See**: `docs/prompts/CLAUDE_PROJECT_SETUP.md` for detailed setup

**Quick Setup**:
```
1. Create Project in Claude.ai
2. Upload knowledge files:
 - backend/CLAUDE.md
 - frontend/CLAUDE.md
 - docs/ARCHITECTURE.md
 - docs/FULLSTACK_WORKFLOW.md
 - backend/docs/FEATURE_WORKFLOW.md
 - frontend/docs/FEATURE_WORKFLOW.md
3. Set custom instructions:
 "You are an expert fullstack developer helping plan features for a
 SaaS boilerplate. Generate detailed, actionable prompts for Claude Code."
```

### Workflow Integration

```
┌─────────────────────────────────────┐
│ Claude.ai Project │
│ (Planning & Architecture) │
│ │
│ User: "Design notification system" │
│ Claude: [Analyzes, designs plan] │
│ Output: Implementation prompts │
└──────────────┬──────────────────────┘
 │
 │ Copy prompts
 ▼
┌─────────────────────────────────────┐
│ Claude Code │
│ (Implementation) │
│ │
│ Paste: Prompt 1 (Models) │
│ Claude: [Implements] │
│ Paste: Prompt 2 (Endpoints) │
│ Claude: [Implements] │
│ ... │
│ Result: Working feature │
└─────────────────────────────────────┘
```

## I. Checklist

### Pre-Flight Checklist

Before starting a Claude Code session:

- [ ] **Services running**: `docker compose up -d`
- [ ] **Database up-to-date**: `docker compose exec backend alembic current`
- [ ] **Dependencies installed**: Backend & Frontend up-to-date
- [ ] **Git clean**: Commit or stash work-in-progress
- [ ] **Model selected**: Sonnet (default) or Opus (complex tasks)
- [ ] **Plan mode decision**: Use for features affecting 3+ files
- [ ] **Token budget**: Check you have budget for session
- [ ] **Context prepared**: Have error messages, logs, requirements ready

### Post-Implementation Checklist

After Claude implements a feature:

- [ ] **Code review**: Read changes, verify they make sense
- [ ] **Types generated**: Run `npm run generate:types` if backend schemas changed
- [ ] **Tests pass**: Run backend and frontend tests
- [ ] **Manual testing**: Test feature in browser/API
- [ ] **Permissions work**: Verify backend enforces, frontend shows/hides
- [ ] **Errors handled**: Check error cases display correctly
- [ ] **Documentation updated**: Update docs if patterns changed
- [ ] **Commit**: Create atomic commit with descriptive message
- [ ] **Token usage**: Review session token usage for optimization

## Summary

**Key Takeaways**:

1. **Model Selection**: Sonnet for most tasks, Opus for complex problems
2. **Plan Mode**: Use for features affecting 3+ files, saves tokens and rework
3. **Token Management**: Use references, skills, and new sessions to optimize
4. **Workflows**: Two-stage (Project → Code) for complex, Direct for simple
5. **Skills**: Pre-optimized prompts for consistency and speed
6. **Debugging**: Provide rich context, use Opus when stuck
7. **Sessions**: One feature per session, commit frequently
8. **Integration**: Use Project for planning, Code for implementation
9. **Checklists**: Verify setup before and after implementation

**Next Steps**:
- **New to boilerplate?** → Read `GETTING_STARTED.md`
- **Planning a feature?** → Use `docs/FULLSTACK_WORKFLOW.md`
- **Set up Claude.ai Project?** → See `docs/prompts/CLAUDE_PROJECT_SETUP.md`
- **Need code patterns?** → See `docs/prompts/integration-patterns.md`
