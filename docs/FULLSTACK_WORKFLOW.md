# Fullstack Feature Workflow

Complete end-to-end workflows for implementing features across backend and frontend with Claude Code integration.

## Overview

Two primary approaches:

1. **Backend-First** (Recommended) - Define data models and API first, then build UI
2. **Frontend-First** - Design UI/UX first, then implement backend to support it

**When to use Backend-First**:
- ✅ Data-driven features (CRUD, dashboards, reports)
- ✅ Complex business logic or validation
- ✅ Features requiring database design
- ✅ Multiple frontend consumers (web + mobile)

**When to use Frontend-First**:
- ✅ UI/UX prototyping or experimentation
- ✅ Design-heavy features (landing pages, marketing)
- ✅ Features with unclear requirements (iterate on UI first)
- ✅ Visual components with minimal backend needs

## Prerequisites

1. **Services Running**: `docker compose up -d`
2. **Backend**: http://localhost:8000 (verify `/docs` accessible)
3. **Frontend**: http://localhost:5173 (verify app loads)
4. **Claude Code**: Read `CLAUDE_CODE_BEST_PRACTICES.md` for optimization tips

## Backend-First Workflow

### Phase 1: Plan & Design (Claude.ai Project - Optional)

**Use Claude.ai Project for initial planning** (see `docs/prompts/CLAUDE_PROJECT_SETUP.md`):

```
User: "I need a product catalog feature with categories, pricing tiers, and inventory tracking"

Claude (Project): Here's a plan...

1. Database Schema
   - Product model: id, name, description, price, sku, category_id, stock_quantity
   - Category model: id, name, parent_id (self-referential)
   - PricingTier model: id, product_id, min_quantity, price

2. API Endpoints
   - GET /products (list, filter, paginate)
   - POST /products (create)
   - GET /products/{id} (detail)
   - ...

3. Permissions Needed
   - PRODUCTS_READ, PRODUCTS_WRITE, PRODUCTS_DELETE
   - CATEGORIES_MANAGE

4. Frontend Components
   - ProductList, ProductForm, CategoryTree, InventoryBadge

[Detailed prompts for each phase...]
```

**Output**: Copy prompts to Claude Code for implementation.

### Phase 2: Backend Implementation

**2.1 Create Database Models**

Use `fastapi-model` skill or implement manually:

```bash
# In Claude Code
/fastapi-model

# Or provide prompt:
"Create Product model with fields: name (str), description (str), price (Decimal),
sku (str, unique), category_id (UUID, FK to categories), stock_quantity (int).
Include created_at, updated_at timestamps and soft delete."
```

**Verify**:
```bash
# Check model file created
ls backend/app/models/product.py

# Review generated code
cat backend/app/models/product.py
```

**2.2 Create Migration**

Use `fastapi-migration` skill:

```bash
/fastapi-migration

# Prompt: "Create migration for Product and Category models"
```

**Verify & Apply**:
```bash
# Review migration
ls backend/app/alembic/versions/

# Apply migration
docker compose exec backend alembic upgrade head

# Verify in database
docker compose exec backend alembic current
```

**2.3 Add Permissions**

Use `fastapi-permission` skill:

```bash
/fastapi-permission

# Prompt: "Add PRODUCTS_READ, PRODUCTS_WRITE, PRODUCTS_DELETE permissions"
```

**Verify**:
- Check `backend/app/models/permission.py` updated
- Migration created for new permissions
- Run migration: `alembic upgrade head`

**2.4 Create API Endpoint**

Use `fastapi-endpoint` skill:

```bash
/fastapi-endpoint

# Prompt: "Create CRUD endpoints for Product with permissions:
# - GET /products (PRODUCTS_READ) - list with pagination, filter by category
# - POST /products (PRODUCTS_WRITE) - create product
# - GET /products/{id} (PRODUCTS_READ) - get single
# - PUT /products/{id} (PRODUCTS_WRITE) - update
# - DELETE /products/{id} (PRODUCTS_DELETE) - soft delete"
```

**Generated Files**:
- `backend/app/schemas/product.py` - Pydantic schemas
- `backend/app/repositories/product_repository.py` - Database queries
- `backend/app/services/product_service.py` - Business logic
- `backend/app/api/v1/endpoints/products.py` - REST routes

**2.5 Write Tests**

Use `fastapi-test` skill:

```bash
/fastapi-test

# Prompt: "Create tests for Product endpoints covering:
# - List products with pagination
# - Create product (valid and invalid data)
# - Get product (exists and not found)
# - Update product with permission checks
# - Delete product (soft delete)"
```

**Run Tests**:
```bash
docker compose exec backend pytest backend/tests/test_products.py -v
```

### Phase 3: Generate Frontend Types

**After backend schema is stable**:

```bash
# Ensure backend is running
curl http://localhost:8000/docs

# Generate TypeScript types
cd frontend
npm run generate:types

# Verify generated types
grep -A 10 "ProductResponse" src/types/generated/api.ts
```

**Output**: `frontend/src/types/generated/api.ts` contains:
- `ProductResponse`, `ProductCreate`, `ProductUpdate` types
- `Permission` enum with `PRODUCTS_READ`, etc.

### Phase 4: Frontend Implementation

**See**: `frontend/docs/FEATURE_WORKFLOW.md` for detailed frontend workflow.

**4.1 Create API Integration**

Use `api-integration` skill:

```bash
/api-integration

# Prompt: "Create API integration for products with:
# - getProducts(params) - list with filters
# - getProduct(id) - single product
# - createProduct(data) - create
# - updateProduct(id, data) - update
# - deleteProduct(id) - delete
# Include TanStack Query hooks."
```

**Generated Files**:
- `frontend/src/features/products/api/products.ts` - API functions
- `frontend/src/features/products/hooks/useProducts.ts` - React Query hooks

**4.2 Create Components**

Use `react-component` skill:

```bash
/react-component

# Prompt: "Create ProductCard component displaying:
# - Product name, description
# - Price with formatting
# - Stock quantity badge (red if < 10, yellow if < 50)
# - Category breadcrumb
# - Edit/Delete buttons (with permission checks)"
```

**4.3 Create Forms**

Use `react-form` skill:

```bash
/react-form

# Prompt: "Create ProductForm with fields:
# - name (required, max 200 chars)
# - description (optional, textarea)
# - price (required, positive decimal)
# - sku (required, unique, alphanumeric)
# - category (required, select from categories)
# - stock_quantity (required, positive integer)
# Validate with Zod, handle create/edit modes."
```

**4.4 Create Page**

Use `react-page` skill:

```bash
/react-page

# Prompt: "Create ProductsPage at /products with:
# - ProductList component showing cards
# - Filter by category
# - Search by name/SKU
# - Pagination
# - 'Add Product' button (permission: PRODUCTS_WRITE)"
```

### Phase 5: Integration Testing

**5.1 Manual Testing**:

```bash
# Backend API
curl -X POST http://localhost:8000/api/v1/products \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Product", "price": 29.99, ...}'

# Frontend
# Open http://localhost:5173/products
# Test CRUD operations via UI
```

**5.2 Check Integration Points**:

- ✅ **Types**: Frontend uses generated types (no `any`)
- ✅ **Permissions**: Backend enforces, frontend shows/hides UI
- ✅ **Errors**: Backend exceptions → Frontend toasts
- ✅ **Loading**: TanStack Query manages loading states
- ✅ **Validation**: Zod schemas match Pydantic schemas

**5.3 Network Tab Verification**:

- ✅ Requests include `Authorization: Bearer ...`
- ✅ 401 responses trigger token refresh
- ✅ Error responses show in toast notifications
- ✅ Pagination params sent correctly

### Phase 6: Commit & Document

**6.1 Review Changes**:

```bash
git status
git diff
```

**6.2 Use Commit Skill** (if available):

```bash
# In Claude Code
/commit

# Or manually:
git add backend/app/models/product.py \
        backend/app/schemas/product.py \
        backend/app/repositories/product_repository.py \
        ...
        frontend/src/features/products/

git commit -m "Add product catalog feature

- Backend: Product and Category models with CRUD endpoints
- Permissions: PRODUCTS_READ, PRODUCTS_WRITE, PRODUCTS_DELETE
- Frontend: Product list, form, and detail pages
- Tests: Backend unit and integration tests

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

## Frontend-First Workflow

**Use when**: Prototyping UI, unclear requirements, design-heavy features.

### Phase 1: UI Design & Prototyping

**1.1 Create Mock Data**:

```typescript
// frontend/src/features/products/mocks/products.ts
export const mockProducts = [
  {
    id: '1',
    name: 'Widget Pro',
    price: 29.99,
    stock: 45,
    category: 'Electronics'
  },
  // ... more mock data
];
```

**1.2 Build Components with Mocks**:

```bash
# Use react-component skill
/react-component

# Prompt: "Create ProductCard using mock data from mocks/products.ts"
```

**1.3 Create Interactive Prototype**:

- Build forms, lists, modals with mock data
- Test UX flows without backend
- Get stakeholder feedback

### Phase 2: Define Backend Contract

**2.1 Document Required API**:

Based on frontend needs, define:
```typescript
// Document what backend needs to provide
interface ProductAPI {
  // GET /products?page=1&size=10&category=electronics
  getProducts(params: {
    page?: number;
    size?: number;
    category?: string;
  }): Promise<{ items: Product[]; total: number }>;

  // POST /products
  createProduct(data: ProductCreate): Promise<Product>;

  // ...
}
```

### Phase 3: Backend Implementation

Follow **Backend-First Workflow Phase 2** using the contract defined above.

### Phase 4: Connect Frontend to Real API

**4.1 Replace Mocks with API Calls**:

```bash
/api-integration

# Prompt: "Create API integration for products matching ProductAPI interface"
```

**4.2 Update Components**:

```typescript
// Before (mock)
import { mockProducts } from '../mocks/products';
const products = mockProducts;

// After (real API)
import { useProducts } from '../hooks/useProducts';
const { data: products, isLoading } = useProducts();
```

### Phase 5: Testing & Refinement

Same as Backend-First Phase 5.

## Two-Stage Workflow Deep Dive

### Stage 1: Planning in Claude.ai Project

**Why Use Claude.ai Project First?**
- 📚 Unlimited context with knowledge files
- 🧠 Better for complex planning and architecture
- 📝 Can reference entire codebase patterns
- 💡 Generates detailed implementation prompts

**Setup**: See `docs/prompts/CLAUDE_PROJECT_SETUP.md`

**Example Session**:

```
User: "Design a multi-tenant feature where users can create organizations,
invite members, and assign roles. Organizations have subscription tiers."

Claude (Project):
I'll design this feature following your boilerplate patterns.

## Database Schema

1. Organization Model
   - id: UUID (PK)
   - name: str
   - slug: str (unique)
   - tier: Enum['free', 'pro', 'enterprise']
   - created_by: UUID (FK to users)

2. OrganizationMember Model (junction table)
   - org_id: UUID (FK)
   - user_id: UUID (FK)
   - role: Enum['owner', 'admin', 'member']

3. Migration considerations:
   - Add org_id to existing tables that need multi-tenancy
   - Create indexes on org_id for query performance

## Permissions Required
- ORGS_READ, ORGS_WRITE, ORGS_DELETE
- ORGS_INVITE, ORGS_MANAGE_MEMBERS
- ORGS_MANAGE_SUBSCRIPTION

## Implementation Prompts

### Backend Prompt 1: Models
[Copy this to Claude Code]

"Create Organization and OrganizationMember models:

Organization:
- id (UUID, PK)
- name (str, max 100 chars)
- slug (str, unique, index)
- tier (Enum: FREE, PRO, ENTERPRISE)
- created_by (UUID, FK to users)
- settings (JSONB for flexible config)
- created_at, updated_at

OrganizationMember:
- org_id (UUID, FK, part of composite PK)
- user_id (UUID, FK, part of composite PK)
- role (Enum: OWNER, ADMIN, MEMBER)
- invited_by (UUID, FK to users)
- joined_at

Include relationships:
- Organization.members (relationship to User via OrganizationMember)
- Organization.created_by (relationship to User)
- User.organizations (relationship to Organization via OrganizationMember)"

### Backend Prompt 2: Endpoints
[Copy this to Claude Code after models are done]

"Create organization CRUD endpoints:
- POST /orgs - Create organization (sets creator as OWNER)
- GET /orgs - List user's organizations
- GET /orgs/{slug} - Get by slug
- PUT /orgs/{slug} - Update (requires ADMIN role)
- DELETE /orgs/{slug} - Delete (requires OWNER role)
- POST /orgs/{slug}/invite - Invite member (requires ADMIN)
- DELETE /orgs/{slug}/members/{user_id} - Remove member (requires ADMIN)

Permissions: ORGS_READ, ORGS_WRITE, ORGS_DELETE, ORGS_INVITE
Role checks: Verify user's role in organization for mutations"

### Frontend Prompt 1: API Integration
[Copy this to Claude Code after backend is done]

"Create organization API integration:
- getOrganizations() - List user's orgs
- getOrganization(slug) - Get single org
- createOrganization(data) - Create new org
- updateOrganization(slug, data) - Update
- deleteOrganization(slug) - Delete
- inviteMember(slug, email, role) - Invite
- removeMember(slug, userId) - Remove member

Include TanStack Query hooks with proper cache invalidation."

[... more detailed prompts for forms, pages, etc.]

## Architecture Notes
- Use slug for public URLs (not UUID)
- Store settings in JSONB for tier-specific features
- Cache user's org list (invalidate on join/leave)
- Show org switcher in nav if user has multiple orgs
```

### Stage 2: Implementation in Claude Code

**Copy prompts from Project → Execute in Code**:

1. Start new Claude Code session
2. Paste Backend Prompt 1 → Implement models
3. Paste Backend Prompt 2 → Implement endpoints
4. Generate types: `npm run generate:types`
5. Paste Frontend Prompt 1 → Implement API integration
6. Continue with remaining prompts

**Benefits**:
- ✅ Detailed plan reduces back-and-forth in Code
- ✅ Prompts optimized for Claude Code execution
- ✅ Token-efficient (Code doesn't re-plan)
- ✅ Consistent with boilerplate patterns

## Common Scenarios

### CRUD Feature (e.g., Products, Orders)

**Recommended**: Backend-First
1. Models → Migration → Permissions → Endpoint → Tests
2. Generate types
3. API integration → Form → List page → Detail page

**Time**: ~30-60 minutes with Claude Code

### Dashboard Widget (e.g., Sales Chart)

**Recommended**: Frontend-First (if data source exists)
1. Mock chart data
2. Build chart component
3. Create backend aggregation endpoint
4. Connect real data

**Time**: ~20-30 minutes

### Form-Heavy Feature (e.g., Multi-Step Wizard)

**Recommended**: Frontend-First
1. Design all steps with mock data
2. Test UX flow
3. Define backend contract (what data is needed)
4. Implement backend endpoint (single POST to process wizard)
5. Connect frontend

**Time**: ~45-90 minutes

### Report/Export Feature

**Recommended**: Backend-First
1. Create backend endpoint with aggregation logic
2. Add export formats (CSV, PDF)
3. Build frontend trigger button
4. Stream download

**Time**: ~30-45 minutes

## Troubleshooting

### Type Mismatches

**Problem**: TypeScript errors after generating types

```typescript
// Error: Type 'string' is not assignable to type 'number'
const product: ProductResponse = {
  price: "29.99"  // ❌ Backend sends string, frontend expects number
};
```

**Solution**:
1. Check backend Pydantic schema (`backend/app/schemas/product.py`)
2. Verify field type matches intent (use `Decimal` for money, not `str`)
3. Regenerate types: `npm run generate:types`
4. If backend is correct, fix frontend usage

### 401 Unauthorized

**Problem**: API calls return 401 even after login

**Debug**:
```typescript
// Check token exists
console.log(localStorage.getItem('access_token'));

// Check Authorization header sent
// (Open Network tab → Request Headers)
```

**Solutions**:
- Token expired → Should auto-refresh via interceptor
- Token not sent → Check axios interceptor in `api-client.ts`
- Backend JWT secret mismatch → Check `backend/.env`

### 403 Forbidden

**Problem**: Logged in but can't access endpoint

**Debug**:
1. Check user's permissions:
   ```bash
   # In backend shell
   docker compose exec backend python
   >>> from app.models.user import User
   >>> user = await session.get(User, "user-uuid")
   >>> print([p.name for r in user.roles for p in r.permissions])
   ```

2. Check endpoint required permissions:
   ```python
   # backend/app/api/v1/endpoints/products.py
   @require_permissions(Permission.PRODUCTS_WRITE)  # ← Requires this
   ```

**Solution**: Add permission to user's role (see `backend/docs/FEATURE_WORKFLOW.md`)

### CORS Errors

**Problem**: Browser blocks requests with CORS error

**Check Backend**:
```python
# backend/app/core/config.py
BACKEND_CORS_ORIGINS = [
    "http://localhost:5173",  # ← Must include frontend URL
]
```

**Solution**: Add frontend URL to `BACKEND_CORS_ORIGINS` in `.env`

### Type Generation Fails

**Problem**: `npm run generate:types` throws error

**Debug**:
```bash
# Check backend OpenAPI endpoint
curl http://localhost:8000/openapi.json | jq .

# Check backend is running
curl http://localhost:8000/docs
```

**Solutions**:
- Backend not running → `docker compose up -d backend`
- Invalid OpenAPI spec → Check backend logs for Pydantic errors
- Network issue → Verify `package.json` script uses correct URL

## Best Practices

### DO
- ✅ Use skills (`/fastapi-endpoint`, `/react-form`) for consistency
- ✅ Generate types after every backend schema change
- ✅ Write tests for backend endpoints before frontend integration
- ✅ Use Claude.ai Project for complex planning, Claude Code for implementation
- ✅ Commit backend and frontend together (atomic feature)
- ✅ Check permissions work on both backend (enforce) and frontend (UX)

### DON'T
- ❌ Skip type generation (leads to runtime errors)
- ❌ Implement frontend before backend contract is stable (causes rework)
- ❌ Manually edit generated types
- ❌ Skip migration after model changes
- ❌ Rely on frontend permission checks for security
- ❌ Commit backend without regenerating frontend types

### Token Optimization

**See**: `CLAUDE_CODE_BEST_PRACTICES.md` Section C for detailed strategies.

**Quick Tips**:
- Use Plan Mode for complex features (get approval before implementation)
- Reference docs instead of repeating ("`backend/CLAUDE.md` has details")
- Use skills instead of manual prompts (pre-optimized)
- Start new session for unrelated features (avoid context bloat)

## Next Steps

- **New feature?** → Choose Backend-First or Frontend-First approach
- **Complex planning?** → Use Claude.ai Project first (see `docs/prompts/CLAUDE_PROJECT_SETUP.md`)
- **Need code examples?** → See `docs/prompts/integration-patterns.md`
- **Using Claude Code?** → Read `CLAUDE_CODE_BEST_PRACTICES.md` ⭐
