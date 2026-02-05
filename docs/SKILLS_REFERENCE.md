# Skills Reference - Complete Guide

Comprehensive reference for all Claude Code skills in the SaaS Boilerplate. Skills are AI-assisted code generation templates that follow project conventions.

## Table of Contents

- [Overview](#overview)
- [Root Skills](#root-skills-fullstack-workflows)
- [Backend Skills](#backend-skills-fastapi)
- [Frontend Skills](#frontend-skills-react)
- [Skill Selection Guide](#skill-selection-guide)
- [Best Practices](#best-practices)

---

## Overview

### What are Skills?

Skills are specialized prompts that guide Claude Code to generate code following your project's patterns, conventions, and architecture. They ensure consistency and reduce boilerplate.

### Skills vs Manual Development

| Aspect | With Skills | Without Skills |
|--------|-------------|----------------|
| **Speed** | 5-10x faster | Baseline |
| **Consistency** | Always follows patterns | Varies by developer |
| **Boilerplate** | Auto-generated | Manual copy-paste |
| **Learning curve** | Minimal (guided) | Steep (read all docs) |
| **Error rate** | Low (patterns tested) | Higher (easy to miss steps) |

### How to Use Skills

```bash
# Start Claude Code
claude-code

# Invoke skill by name
/skill-name

# Or ask Claude to use appropriate skill
"Create a CRUD endpoint for Products using the fastapi-endpoint skill"
```

**Important**: Skills are **optional tools**. You can develop features manually following the documentation.

---

## Root Skills (Fullstack Workflows)

These skills orchestrate both backend and frontend implementation.

### `/backend-first`

**Category**: Fullstack Workflow
**Status**: [X] Active
**Recommended**: Yes (for data-driven features)

**Description**: Implement complete fullstack feature using backend-first workflow: define data models → API → generate types → build UI.

**When to Use**:
- [X] CRUD resources (products, orders, users)
- [X] Data-driven features (dashboards, reports)
- [X] Features with clear data requirements
- [X] Features needing database design

**Workflow**:
1. Backend: Models → Migrations → Schemas → Repositories → Services → Endpoints → Tests
2. Type Generation: `npm run generate:types`
3. Frontend: API functions → React Query hooks → Zod schemas → Components → Pages
4. Integration: E2E testing

**Example Usage**:
```
/backend-first

Prompt: "Create a Products catalog feature with:
- Fields: name, description, SKU, price, stock_quantity, category_id
- PostgreSQL for storage
- Permissions: PRODUCTS_READ, PRODUCTS_WRITE, PRODUCTS_DELETE
- Full CRUD with pagination"
```

**Documentation**: `.claude/skills/backend-first/SKILL.md` (1,124 lines)

---

### `/api-to-ui`

**Category**: Fullstack Workflow
**Status**: [X] Active
**Recommended**: For existing APIs

**Description**: Create complete frontend UI integration for an existing backend API endpoint. Use when backend is already implemented.

**When to Use**:
- [X] Backend API exists, need frontend
- [X] Adding new UI for existing data
- [X] Multiple frontend consumers for same API

**Workflow**:
1. Verify backend API is working
2. Generate types: `npm run generate:types`
3. Create API client functions
4. Create React Query hooks
5. Build components and pages
6. Add routes

**Example Usage**:
```
/api-to-ui

Prompt: "Create frontend for the Products API:
- List page with pagination
- Detail page
- Create/Edit form with validation
- Permission-based UI (hide delete for non-admins)"
```

**Documentation**: `.claude/skills/api-to-ui/SKILL.md`

---

### `/fullstack-feature`

**Category**: Fullstack Workflow
**Status**: [X] Active
**Recommended**: For greenfield features

**Description**: Create complete CRUD feature from scratch with backend API, database models, frontend UI, authentication, and permissions. Most comprehensive skill.

**When to Use**:
- [X] Greenfield features (nothing exists)
- [X] Complete resource implementation needed
- [X] Need all layers (DB → API → UI)

**Workflow**:
Combines `/backend-first` and `/api-to-ui` into single workflow with additional:
- i18n translations
- Permission setup
- Full test coverage

**Example Usage**:
```
/fullstack-feature

Prompt: "Create complete Blog feature:
- Models: Post (title, content, author_id, published_at)
- CRUD with draft/published states
- Only authors can edit their posts
- Admin can edit/delete any post
- Public can read published posts"
```

**Documentation**: `.claude/skills/fullstack-feature/SKILL.md`

---

## Backend Skills (FastAPI)

These skills generate backend code following repository pattern and clean architecture.

### `/fastapi-endpoint`

**Category**: Backend API
**Status**: [X] Active
**Recommended**: Yes

**Description**: Generate complete CRUD endpoint with schema, repository, service, and router. Handles dependency injection, permissions, and error handling.

**When to Use**:
- [X] Need REST API endpoints
- [X] CRUD operations
- [X] Permission-protected routes

**Generates**:
- `app/schemas/{resource}.py` - Pydantic schemas (Create, Update, Response)
- `app/repositories/{resource}_repository.py` - Database access layer
- `app/services/{resource}_service.py` - Business logic
- `app/api/v1/endpoints/{resource}.py` - FastAPI router with all CRUD operations

**Example Usage**:
```
/fastapi-endpoint

Prompt: "Create CRUD endpoints for Categories:
- Fields: name (str, required), description (str, optional)
- Permission: CATEGORIES_READ, CATEGORIES_WRITE
- Pagination for list endpoint"
```

**Patterns**:
```python
# Endpoint pattern
@router.get("/", response_model=list[ResourceResponse])
@require_permissions(Permission.RESOURCE_READ)
async def list_resources(
 page: int = 1,
 size: int = 10,
 service: ResourceService = Depends(get_resource_service),
 current_user: User = Depends(get_current_user)
):
 return await service.list_resources(page=page, size=size)
```

**Documentation**: `backend/.claude/skills/fastapi-endpoint/SKILL.md`

---

### `/fastapi-model`

**Category**: Backend Models
**Status**: [X] Active
**Recommended**: Yes

**Description**: Create SQLAlchemy models (PostgreSQL) or MongoDB documents with proper typing, relationships, and indexes.

**When to Use**:
- [X] Need new database models
- [X] Define schema before endpoints
- [X] Complex relationships

**Generates**:
- `app/models/postgres/{model}.py` - SQLAlchemy model with type hints
- OR `app/models/mongodb/{document}.py` - MongoDB document

**Example Usage**:
```
/fastapi-model

Prompt: "Create PostgreSQL model for Orders:
- UUID primary key
- Fields: order_number (unique), total_amount (Decimal), status (Enum)
- Relationships: user_id (FK to users), items (one-to-many to OrderItems)
- Timestamps: created_at, updated_at
- Soft delete: is_active"
```

**Patterns**:
```python
# PostgreSQL Model
class Order(Base):
 __tablename__ = "orders"

 id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
 order_number: Mapped[str] = mapped_column(String(50), unique=True, index=True)
 total_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2))
 status: Mapped[OrderStatus] = mapped_column(Enum(OrderStatus))
 user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
 is_active: Mapped[bool] = mapped_column(Boolean, default=True)
 created_at: Mapped[datetime]
 updated_at: Mapped[datetime]

 # Relationships
 user: Mapped["User"] = relationship(back_populates="orders")
 items: Mapped[list["OrderItem"]] = relationship(back_populates="order")
```

**Documentation**: `backend/.claude/skills/fastapi-model/SKILL.md`

---

### `/fastapi-migration`

**Category**: Backend Migrations
**Status**: [X] Active
**Recommended**: Yes (after model creation)

**Description**: Create and manage Alembic database migrations for PostgreSQL schema changes.

**When to Use**:
- [X] After creating/modifying PostgreSQL models
- [X] Need to apply schema changes
- [X] Add indexes or constraints

**Workflow**:
1. Create migration: `alembic revision --autogenerate -m "description"`
2. Review generated migration file
3. Apply: `alembic upgrade head`
4. Verify: `alembic current`

**Example Usage**:
```
/fastapi-migration

Prompt: "Create migration for Orders model:
- Add orders table
- Add foreign key to users
- Add unique constraint on order_number
- Add index on created_at for performance"
```

**Important**: Always review auto-generated migrations before applying!

**Documentation**: `backend/.claude/skills/fastapi-migration/SKILL.md`

---

### `/fastapi-permission`

**Category**: Backend RBAC
**Status**: [X] Active
**Recommended**: For permission-protected features

**Description**: Add new permissions to RBAC system, create migration, and assign to roles.

**When to Use**:
- [X] New feature needs access control
- [X] Adding permissions to existing feature
- [X] Modifying role permissions

**Generates**:
- Updates to `app/common/permissions.py` (Permission enum)
- Alembic migration to insert permissions
- Role-permission mappings

**Example Usage**:
```
/fastapi-permission

Prompt: "Add permissions for Reports feature:
- REPORTS_READ (all users)
- REPORTS_WRITE (admin only)
- REPORTS_DELETE (admin only)
- REPORTS_EXPORT (premium users + admin)"
```

**Patterns**:
```python
# Permission enum
class Permission(str, Enum):
 REPORTS_READ = "reports:read"
 REPORTS_WRITE = "reports:write"
 REPORTS_DELETE = "reports:delete"
 REPORTS_EXPORT = "reports:export"

# Role mappings
ROLE_PERMISSIONS = {
 Role.ADMIN: {Permission.REPORTS_READ, Permission.REPORTS_WRITE,
 Permission.REPORTS_DELETE, Permission.REPORTS_EXPORT},
 Role.USER: {Permission.REPORTS_READ},
 Role.PREMIUM: {Permission.REPORTS_READ, Permission.REPORTS_EXPORT},
}
```

**Documentation**: `backend/.claude/skills/fastapi-permission/SKILL.md`

---

### `/fastapi-test`

**Category**: Backend Testing
**Status**: [X] Active
**Recommended**: Always (test-driven development)

**Description**: Generate comprehensive unit and integration tests with pytest.

**When to Use**:
- [X] After implementing feature
- [X] Test-driven development
- [X] Need test coverage

**Generates**:
- `tests/unit/services/test_{service}.py` - Service unit tests
- `tests/unit/repositories/test_{repository}.py` - Repository tests
- `tests/integration/test_{endpoint}.py` - API integration tests

**Example Usage**:
```
/fastapi-test

Prompt: "Create tests for Orders API:
- Unit tests: OrderService methods
- Integration tests: All CRUD endpoints
- Permission tests: Verify RBAC works
- Edge cases: Invalid order_number, negative amounts"
```

**Patterns**:
```python
# Integration test
@pytest.mark.asyncio
async def test_create_order(client: AsyncClient, admin_token: str):
 response = await client.post(
 "/api/v1/orders",
 json={"order_number": "ORD-001", "total_amount": 99.99},
 headers={"Authorization": f"Bearer {admin_token}"}
 )
 assert response.status_code == 201
 data = response.json()
 assert data["order_number"] == "ORD-001"
```

**Documentation**: `backend/.claude/skills/fastapi-test/SKILL.md`

---

### `/feature-from-plan`

**Category**: Backend Workflow
**Status**: [X] Active
**Use Case**: Complex features with design doc

**Description**: Implement backend feature from existing design document or plan. Useful for complex multi-step features.

**When to Use**:
- [X] Have detailed design doc
- [X] Complex feature with multiple models
- [X] Need to follow specific architecture

**Example Usage**:
```
/feature-from-plan

Prompt: "Implement Order Processing system based on this design:
[Paste design document]
- Order → OrderItem relationship
- Payment processing service
- Inventory reservation
- Email notifications
- State machine for order status"
```

**Documentation**: `backend/.claude/skills/feature-from-plan/SKILL.md`

---

## Frontend Skills (React)

These skills generate React components, forms, and pages following project patterns.

### `/react-component`

**Category**: Frontend Components
**Status**: [X] Active
**Recommended**: For reusable UI

**Description**: Create feature-specific React components with TypeScript, Tailwind, and shadcn/ui.

**When to Use**:
- [X] Need reusable component
- [X] Complex UI element
- [X] Form component

**Generates**:
- `src/features/{feature}/components/{Component}.tsx`
- TypeScript interface for props
- Tailwind styling
- shadcn/ui integration

**Example Usage**:
```
/react-component

Prompt: "Create ProductCard component:
- Shows product image, name, price, stock status
- Actions: Edit (permission: PRODUCTS_WRITE), Delete (permission: PRODUCTS_DELETE)
- Props: product (ProductResponse), onEdit, onDelete
- Use Card from shadcn/ui"
```

**Patterns**:
```typescript
interface ProductCardProps {
 product: ProductResponse;
 onEdit?: (id: string) => void;
 onDelete?: (id: string) => void;
}

export const ProductCard = ({ product, onEdit, onDelete }: ProductCardProps) => {
 return (
 <Card>
 <CardContent>
 <h3 className="text-lg font-semibold">{product.name}</h3>
 <p className="text-2xl">${product.price}</p>
 </CardContent>
 <CardFooter className="gap-2">
 <Can permission="PRODUCTS_WRITE">
 <Button onClick={() => onEdit?.(product.id)}>Edit</Button>
 </Can>
 <Can permission="PRODUCTS_DELETE">
 <Button variant="destructive" onClick={() => onDelete?.(product.id)}>
 Delete
 </Button>
 </Can>
 </CardFooter>
 </Card>
 );
};
```

**Documentation**: `frontend/.claude/skills/react-component/SKILL.md`

---

### `/react-form`

**Category**: Frontend Forms
**Status**: [X] Active
**Recommended**: For data input

**Description**: Create forms with react-hook-form + Zod validation + shadcn/ui components.

**When to Use**:
- [X] Need form with validation
- [X] Create/edit operations
- [X] Complex multi-field forms

**Generates**:
- `src/features/{feature}/schemas/{schema}.ts` - Zod schema
- `src/features/{feature}/components/{Form}.tsx` - Form component
- Type-safe form with error messages

**Example Usage**:
```
/react-form

Prompt: "Create ProductForm:
- Fields: name (required, max 200), SKU (required, unique),
 price (number, positive), stock_quantity (integer, min 0)
- Zod validation with custom error messages
- Submit handler prop
- Pre-fill for edit mode"
```

**Patterns**:
```typescript
// Schema
export const productSchema = z.object({
 name: z.string().min(1, 'Name is required').max(200),
 sku: z.string().min(1, 'SKU is required'),
 price: z.number().positive('Price must be positive'),
 stock_quantity: z.number().int().min(0, 'Stock cannot be negative'),
});

// Form component
const form = useForm<ProductFormData>({
 resolver: zodResolver(productSchema),
 defaultValues: product || { name: '', sku: '', price: 0, stock_quantity: 0 },
});
```

**Documentation**: `frontend/.claude/skills/react-form/SKILL.md`

---

### `/api-integration`

**Category**: Frontend API
**Status**: [X] Active
**Recommended**: Yes

**Description**: Create API integration with TanStack Query hooks. Type-safe API calls with caching and mutations.

**When to Use**:
- [X] Need to call backend API
- [X] CRUD operations from frontend
- [X] Real-time data with caching

**Generates**:
- `src/features/{feature}/api/{feature}.api.ts` - API functions
- `src/features/{feature}/hooks/use-{feature}.ts` - React Query hooks

**Example Usage**:
```
/api-integration

Prompt: "Create API integration for Products:
- List with pagination and filters (category, search)
- Get single product
- Create, update, delete mutations
- Cache invalidation on mutations
- Toast notifications on success/error"
```

**Patterns**:
```typescript
// API functions
export const productsApi = {
 getProducts: async (params?: {page?: number; size?: number}) => {
 const { data } = await apiClient.get<PaginatedResponse<Product>>('/products', { params });
 return data;
 },
 createProduct: async (product: ProductCreate) => {
 const { data } = await apiClient.post<Product>('/products', product);
 return data;
 },
};

// React Query hooks
export const useProducts = (filters?: ProductFilters) => {
 return useQuery({
 queryKey: ['products', filters],
 queryFn: () => productsApi.getProducts(filters),
 });
};

export const useCreateProduct = () => {
 const queryClient = useQueryClient();
 return useMutation({
 mutationFn: productsApi.createProduct,
 onSuccess: () => {
 queryClient.invalidateQueries({ queryKey: ['products'] });
 toast.success('Product created');
 },
 });
};
```

**Documentation**: `frontend/.claude/skills/api-integration/SKILL.md`

---

### `/react-feature`

**Category**: Frontend Feature
**Status**: [X] Active
**Recommended**: For complete features

**Description**: Create complete CRUD feature structure with API integration, hooks, components, and pages.

**When to Use**:
- [X] Need complete frontend feature
- [X] List, create, edit, delete pages
- [X] All layers (API → hooks → components → pages)

**Generates**:
- Feature folder structure
- API integration
- React Query hooks
- Zod schemas
- Components (Card, Form, List)
- Pages (List, Detail, Create/Edit)

**Example Usage**:
```
/react-feature

Prompt: "Create complete Products feature:
- List page with pagination, search, filters
- Detail page with product info
- Create/Edit form in modal
- Delete confirmation
- Permission-based UI
- i18n support (EN/ES)"
```

**Documentation**: `frontend/.claude/skills/react-feature/SKILL.md`

---

### `/react-page`

**Category**: Frontend Pages
**Status**: [X] Active
**Recommended**: For new pages

**Description**: Create page component and add to routing configuration.

**When to Use**:
- [X] Need new page/route
- [X] Dashboard, settings, etc.
- [X] Protected routes

**Generates**:
- `src/features/{feature}/pages/{Page}.tsx` - Page component
- Route configuration in `src/routes/`
- Protected route wrapper (if needed)

**Example Usage**:
```
/react-page

Prompt: "Create Dashboard page:
- Protected route (requires login)
- Permission: DASHBOARD_VIEW
- Show stats: total users, orders today, revenue
- Recent activity feed
- Route: /dashboard"
```

**Documentation**: `frontend/.claude/skills/react-page/SKILL.md`

---

## Skill Selection Guide

### Decision Tree

```
Need to implement feature?
├─ Backend + Frontend?
│ ├─ Backend exists? → /api-to-ui
│ ├─ Nothing exists? → /fullstack-feature or /backend-first
│ └─ Complex feature? → /backend-first (more control)
│
├─ Backend only?
│ ├─ Just API endpoints? → /fastapi-endpoint
│ ├─ Just model? → /fastapi-model
│ ├─ Need tests? → /fastapi-test
│ ├─ Need permissions? → /fastapi-permission
│ └─ Need migration? → /fastapi-migration
│
└─ Frontend only?
 ├─ Complete feature? → /react-feature
 ├─ Just component? → /react-component
 ├─ Just form? → /react-form
 ├─ Just API hooks? → /api-integration
 └─ Just page? → /react-page
```

### By Use Case

| Use Case | Recommended Skill | Alternative |
|----------|------------------|-------------|
| New CRUD resource | `/backend-first` | `/fullstack-feature` |
| Backend API exists, need UI | `/api-to-ui` | Manual frontend |
| Complex multi-model feature | `/feature-from-plan` | `/backend-first` |
| Simple API endpoint | `/fastapi-endpoint` | Manual coding |
| Form with validation | `/react-form` | Manual form |
| Reusable component | `/react-component` | Manual component |
| API integration | `/api-integration` | Manual axios calls |
| Dashboard page | `/react-page` | Manual page |

### By Experience Level

**Beginner** (learning the boilerplate):
- Start with: `/backend-first`, `/react-component`, `/react-form`
- These skills show complete patterns

**Intermediate** (familiar with patterns):
- Use: `/fastapi-endpoint`, `/api-integration`, `/react-feature`
- More focused, assume pattern knowledge

**Advanced** (know patterns by heart):
- Use: Manual coding with occasional skill for boilerplate
- Use skills for speed, not learning

---

## Best Practices

### 1. Read Generated Code

**Always review** what skills generate:
- Understand the patterns
- Learn project conventions
- Verify correctness

### 2. Start with Plan Mode

For complex features:
```bash
# Use Claude Code's plan mode
/plan

"Design and implement Products feature with:
- PostgreSQL model
- CRUD API
- Permission-based access
- Frontend UI with forms"

# Claude will create detailed plan before coding
```

### 3. Iterate and Refine

Skills generate 80-90% of what you need:
- Generate base code with skill
- Refine business logic manually
- Add custom validations
- Polish UI/UX

### 4. Combine Skills

For fullstack features, use multiple skills:
```bash
# Backend
/fastapi-model # Model
/fastapi-migration # Migration
/fastapi-permission # Permissions
/fastapi-endpoint # API
/fastapi-test # Tests

# Type generation
cd frontend && npm run generate:types

# Frontend
/api-integration # API hooks
/react-form # Forms
/react-component # Cards/List
/react-page # Pages
```

### 5. Use with Documentation

Skills implement patterns from docs:
- **Backend patterns**: `backend/docs/prompts/backend-patterns.md`
- **Frontend patterns**: `frontend/docs/prompts/frontend-patterns.md`
- **Integration**: `docs/prompts/integration-patterns.md`

Read docs to understand **why** skills generate **what** they generate.

### 6. Two-Stage Workflow (Advanced)

For very complex features:

**Stage 1: Claude.ai Project (Planning)**
- Define feature requirements
- Design architecture
- Generate implementation prompts

**Stage 2: Claude Code (Implementation)**
- Use prompts from Stage 1
- Execute with skills
- Implement efficiently

**See**: `docs/prompts/CLAUDE_PROJECT_SETUP.md`

### 7. Test Generated Code

Always test skills output:
```bash
# Backend tests
cd backend
pytest tests/

# Frontend manual testing
# Navigate to feature in browser
# Test all CRUD operations
# Verify permission checks
```

### 8. Customize as Needed

Skills are **starting points**, not final products:
- Add business logic
- Implement custom validation
- Enhance error handling
- Improve UI/UX
- Add edge case handling

---

## FAQ

### Q: Can I use skills without Claude Code?

**A**: Skills are designed for Claude Code but patterns can be followed manually. Read the SKILL.md files as implementation guides.

### Q: Do skills work with other AI tools?

**A**: Skills are optimized for Claude Code. Other tools may work but behavior not guaranteed.

### Q: Can I create custom skills?

**A**: Yes! Copy existing skill structure:
```
.claude/skills/your-skill/
├── SKILL.md # Skill prompt and examples
└── config.json # Skill metadata (optional)
```

Add to `.claude/settings.json`:
```json
{
 "skills": [
 {
 "name": "your-skill",
 "description": "What it does",
 "location": ".claude/skills/your-skill"
 }
 ]
}
```

### Q: Skills vs templates - what's the difference?

**A**:
- **Templates**: Static code copied and filled in
- **Skills**: AI-generated code adapted to your specific requirements

Skills understand context and generate appropriate solutions.

### Q: Can skills refactor existing code?

**A**: Skills primarily generate new code. For refactoring:
1. Use regular Claude Code prompts
2. Reference skill patterns for consistency
3. Or regenerate with skill and merge changes

### Q: What if skill generates wrong code?

**A**:
1. Review the generated code
2. Refine your prompt with more details
3. Try again or fix manually
4. Report issues to improve skill prompts

---

## Additional Resources

- **Claude Code Docs**: https://claude.com/claude-code
- **Best Practices**: `CLAUDE_CODE_BEST_PRACTICES.md`
- **Workflow Guide**: `docs/FULLSTACK_WORKFLOW.md`
- **Backend Patterns**: `backend/docs/prompts/backend-patterns.md`
- **Frontend Patterns**: `frontend/docs/prompts/frontend-patterns.md`

---

**Last Updated**: 2026-02-05
**Total Skills**: 14 (13 active + 1 feature-from-plan)
