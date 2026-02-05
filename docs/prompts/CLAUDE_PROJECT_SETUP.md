# Claude.ai Project Setup

Configure a Claude.ai Project for fullstack feature planning and architecture design. Use this in conjunction with Claude Code for optimal two-stage workflow.

## Overview

**Two-Stage Workflow**:

1. **Claude.ai Project** (Planning) - Design features with unlimited context
2. **Claude Code** (Implementation) - Execute implementation prompts

**Benefits**:
- 📚 Unlimited context via knowledge files
- 🧠 Better strategic planning
- 📝 Generates optimized prompts for Claude Code
- 💡 References entire codebase patterns
- ⚡ Token-efficient implementation

## One-Time Setup

### Step 1: Create Project

1. Go to https://claude.ai
2. Click "Projects" → "Create Project"
3. Name: "SaaS Boilerplate - Planning"
4. Description: "Fullstack feature planning and architecture for the SaaS boilerplate"

### Step 2: Add Custom Instructions

**Custom Instructions** (paste in Project settings):

```markdown
You are an expert fullstack developer helping plan features for a SaaS boilerplate built with:
- **Backend**: FastAPI + PostgreSQL + MongoDB
- **Frontend**: React + TypeScript + Vite + TanStack Router/Query + shadcn/ui

Your role is to:
1. Analyze feature requests in the context of existing patterns
2. Design complete implementation plans (database, backend, frontend)
3. Generate detailed, actionable prompts optimized for Claude Code execution
4. Identify potential issues and edge cases upfront
5. Ensure consistency with boilerplate conventions

When planning features:
- Reference existing patterns from knowledge files
- Break down implementation into sequential prompts
- Each prompt should be copy-paste ready for Claude Code
- Include acceptance criteria and testing considerations
- Flag any breaking changes or migration concerns

Output format for implementation plans:
1. **Overview** - Feature summary and approach
2. **Database Changes** - Models, migrations, schema changes
3. **Backend Implementation** - Endpoints, permissions, services
4. **Frontend Implementation** - Components, pages, API integration
5. **Testing Strategy** - What to test and how
6. **Implementation Prompts** - Numbered prompts for Claude Code
7. **Acceptance Criteria** - How to verify success
```

### Step 3: Upload Knowledge Files

Upload these files to provide context (click "Add content" → "Upload files"):

**Root Documentation**:
- `CLAUDE.md` - Root orchestration context
- `docs/ARCHITECTURE.md` - System architecture
- `docs/FULLSTACK_WORKFLOW.md` - E2E workflows
- `docs/prompts/integration-patterns.md` - API patterns

**Backend Documentation**:
- `backend/CLAUDE.md` - Backend context
- `backend/docs/FEATURE_WORKFLOW.md` - Backend workflow
- `backend/docs/prompts/backend-patterns.md` - Backend patterns

**Frontend Documentation**:
- `frontend/CLAUDE.md` - Frontend context
- `frontend/docs/FEATURE_WORKFLOW.md` - Frontend workflow
- `frontend/docs/prompts/frontend-patterns.md` - Frontend patterns

**Optional** (upload if you want Claude to reference actual implementation patterns and code examples):
- Example models: `backend/app/models/user.py`
- Example endpoints: `backend/app/api/v1/users.py`
- Example components: `frontend/src/features/auth/components/*`

**Total**: ~8-12 files, well within Project limits

### Step 4: Verify Setup

**Test the Project**:

```
User: "Analyze the boilerplate architecture"

Claude (Project): "Based on the knowledge files, here's the architecture:

The boilerplate uses a monorepo structure with:

Backend:
- FastAPI with async SQLAlchemy for PostgreSQL
- Repository pattern (repositories → services → routes)
- Pydantic V2 for validation
- RBAC with Permission enum
- Alembic for migrations

Frontend:
- React 18 with TypeScript
- Feature-based architecture
- TanStack Query for server state
- Zod validation matching backend schemas
- Type generation from OpenAPI

Integration:
- JWT auth (access 30min, refresh 7d)
- Type safety via OpenAPI → TypeScript generation
- Permission checks on backend (enforce) and frontend (UX)

[... detailed analysis based on uploaded docs]"
```

If Claude can reference uploaded files, setup is complete! ✅

## Usage Example

### Scenario: Adding Product Catalog

**User Request**:
```
"I need a product catalog feature with:
- Products have name, description, price, SKU, categories
- Categories are hierarchical (parent/child)
- Inventory tracking (stock quantity, low stock alerts)
- Price tiers based on quantity (bulk discounts)
- Image uploads (multiple per product)
- Search and filtering by category, price range
- Admin can manage, users can view"
```

**Claude.ai Project Response**:

```markdown
# Product Catalog Feature Plan

## Overview

This feature adds a complete product catalog with hierarchical categories, inventory tracking, and bulk pricing. We'll use:
- PostgreSQL for products, categories, pricing tiers (relational data)
- File storage for images (local dev, S3 for prod)
- Backend-first approach (stable schema before frontend)

## Database Schema

### 1. Product Model
- `id` (UUID, PK)
- `name` (String, max 200 chars, indexed)
- `description` (Text, optional)
- `sku` (String, unique, indexed)
- `base_price` (Decimal(10,2))
- `stock_quantity` (Integer, default 0)
- `low_stock_threshold` (Integer, default 10)
- `category_id` (UUID, FK to categories)
- `is_active` (Boolean, default True)
- `created_by` (UUID, FK to users)
- `created_at`, `updated_at`

### 2. Category Model
- `id` (UUID, PK)
- `name` (String, max 100 chars)
- `slug` (String, unique, indexed)
- `parent_id` (UUID, FK to categories, nullable) ← Self-referential
- `sort_order` (Integer)
- `created_at`, `updated_at`

### 3. PricingTier Model
- `id` (UUID, PK)
- `product_id` (UUID, FK to products)
- `min_quantity` (Integer, e.g., 10)
- `price` (Decimal(10,2))
- Constraint: min_quantity must be unique per product

### 4. ProductImage Model
- `id` (UUID, PK)
- `product_id` (UUID, FK to products)
- `url` (String)
- `is_primary` (Boolean, default False)
- `sort_order` (Integer)
- `created_at`

**Relationships**:
- Product → Category (many-to-one)
- Product → PricingTiers (one-to-many)
- Product → ProductImages (one-to-many)
- Category → Children (one-to-many, self-referential)

## Backend Implementation

### Permissions
- `PRODUCTS_READ` - View products (all users)
- `PRODUCTS_WRITE` - Create/edit products (admin only)
- `PRODUCTS_DELETE` - Delete products (admin only)
- `CATEGORIES_MANAGE` - Manage categories (admin only)

### Endpoints

**Products**:
- `GET /products` - List with filters (category, price range, search, in_stock)
- `GET /products/{id}` - Get single product (with images, pricing tiers)
- `POST /products` - Create product (PRODUCTS_WRITE)
- `PUT /products/{id}` - Update product (PRODUCTS_WRITE)
- `DELETE /products/{id}` - Soft delete (PRODUCTS_DELETE)
- `POST /products/{id}/images` - Upload image (PRODUCTS_WRITE)
- `DELETE /products/{id}/images/{image_id}` - Delete image (PRODUCTS_WRITE)

**Categories**:
- `GET /categories` - List all (tree structure)
- `GET /categories/{slug}` - Get single category
- `POST /categories` - Create (CATEGORIES_MANAGE)
- `PUT /categories/{id}` - Update (CATEGORIES_MANAGE)
- `DELETE /categories/{id}` - Delete (CATEGORIES_MANAGE, check no products)

**Pricing Tiers**:
- Managed via product endpoints (nested in product create/update)

## Frontend Implementation

### Components
- `ProductCard` - Display product in grid/list
- `ProductDetail` - Full product view with images, pricing table
- `ProductForm` - Create/edit form with image upload
- `ProductFilters` - Category tree, price range, search
- `CategoryTree` - Hierarchical category selector
- `PricingTierTable` - Display/edit bulk pricing
- `ImageGallery` - Product images with lightbox
- `StockBadge` - Visual indicator (green/yellow/red based on stock)

### Pages
- `/products` - Product list with filters
- `/products/:id` - Product detail
- `/admin/products` - Admin management (with create/edit)
- `/admin/categories` - Category management

### API Integration
- `useProducts(filters)` - List products with TanStack Query
- `useProduct(id)` - Single product
- `useCreateProduct()` - Mutation for create
- `useUpdateProduct()` - Mutation for update
- `useDeleteProduct()` - Mutation for delete
- `useCategories()` - Category tree
- `useUploadProductImage()` - Image upload mutation

## Implementation Prompts for Claude Code

### Backend Prompt 1: Models
**Copy this to Claude Code:**

```
Create four SQLAlchemy models for the product catalog:

1. Category model:
   - id (UUID, PK)
   - name (String, max 100)
   - slug (String, unique, indexed)
   - parent_id (UUID, FK to categories, nullable) - Self-referential for hierarchy
   - sort_order (Integer)
   - children relationship (back_populates)
   - created_at, updated_at

2. Product model:
   - id (UUID, PK)
   - name (String, max 200, indexed)
   - description (Text, optional)
   - sku (String, unique, indexed)
   - base_price (Decimal(10,2))
   - stock_quantity (Integer, default 0)
   - low_stock_threshold (Integer, default 10)
   - category_id (UUID, FK to categories)
   - is_active (Boolean, default True)
   - created_by (UUID, FK to users)
   - category relationship
   - pricing_tiers relationship (cascade delete)
   - images relationship (cascade delete)
   - created_at, updated_at

3. PricingTier model:
   - id (UUID, PK)
   - product_id (UUID, FK to products)
   - min_quantity (Integer)
   - price (Decimal(10,2))
   - UniqueConstraint(product_id, min_quantity)
   - product relationship

4. ProductImage model:
   - id (UUID, PK)
   - product_id (UUID, FK to products)
   - url (String)
   - is_primary (Boolean, default False)
   - sort_order (Integer)
   - product relationship
   - created_at

Use /fastapi-model skill or implement manually.
```

### Backend Prompt 2: Migrations
**Copy this to Claude Code:**

```
Create Alembic migration for Product, Category, PricingTier, and ProductImage models.
Include indexes on:
- product.name
- product.sku (unique)
- category.slug (unique)

Use /fastapi-migration skill.
```

### Backend Prompt 3: Permissions
**Copy this to Claude Code:**

```
Add permissions to Permission enum:
- PRODUCTS_READ
- PRODUCTS_WRITE
- PRODUCTS_DELETE
- CATEGORIES_MANAGE

Create migration to add these permissions to database.
Assign PRODUCTS_READ to 'user' role, all product permissions to 'admin' role.

Use /fastapi-permission skill.
```

### Backend Prompt 4: Product Endpoints
**Copy this to Claude Code:**

```
Create product CRUD endpoints:

- GET /products - List with filters:
  - page, size (pagination)
  - category_id (filter by category)
  - min_price, max_price (price range)
  - search (search name, description, sku)
  - in_stock (boolean, only show items with stock > 0)
  Returns: Paginated list with category, image count, lowest price tier
  Permission: PRODUCTS_READ (all users)

- GET /products/{id} - Get single product
  Includes: category, pricing_tiers (sorted by min_quantity), images (sorted by sort_order)
  Permission: PRODUCTS_READ

- POST /products - Create product
  Body: ProductCreate schema (name, description, sku, base_price, stock_quantity, category_id, pricing_tiers, low_stock_threshold)
  Returns: Created product
  Permission: PRODUCTS_WRITE

- PUT /products/{id} - Update product
  Body: ProductUpdate schema (all fields optional)
  Permission: PRODUCTS_WRITE

- DELETE /products/{id} - Soft delete (set is_active = False)
  Permission: PRODUCTS_DELETE

Create schemas (ProductCreate, ProductUpdate, ProductResponse with nested tiers/images),
repository, service, and router following project conventions.

Use /fastapi-endpoint skill.
```

### Backend Prompt 5: Category Endpoints
**Copy this to Claude Code:**

```
Create category endpoints:

- GET /categories - List all categories as tree structure
  Returns: Nested JSON with children
  Permission: Public (no auth required)

- GET /categories/{slug} - Get category by slug
  Includes: parent, children, product_count
  Permission: Public

- POST /categories - Create category
  Body: CategoryCreate (name, slug, parent_id, sort_order)
  Permission: CATEGORIES_MANAGE

- PUT /categories/{id} - Update category
  Body: CategoryUpdate
  Permission: CATEGORIES_MANAGE

- DELETE /categories/{id} - Delete category
  Validation: Ensure no products assigned, no child categories
  Permission: CATEGORIES_MANAGE

Use /fastapi-endpoint skill.
```

### Backend Prompt 6: Image Upload
**Copy this to Claude Code:**

```
Add image upload endpoint:

POST /products/{product_id}/images
- Accept multipart/form-data with 'file' field
- Validate: Only JPEG, PNG, WebP (max 5MB)
- Save to ./uploads/products/{product_id}/ in dev (use S3 in prod)
- Create ProductImage record with URL, sort_order
- If is_primary=True in request, unset other primary images
- Return: ProductImage response
- Permission: PRODUCTS_WRITE

DELETE /products/{product_id}/images/{image_id}
- Delete file and database record
- Permission: PRODUCTS_WRITE

Update ProductResponse schema to include images array.
```

### Backend Prompt 7: Tests
**Copy this to Claude Code:**

```
Create pytest tests for product endpoints:
- Test list products with filters (category, price range, search, pagination)
- Test create product with pricing tiers
- Test update product (including nested pricing tiers)
- Test delete product (soft delete)
- Test permission checks (non-admin cannot create/delete)
- Test category tree structure
- Test image upload (valid and invalid files)

Use /fastapi-test skill.
```

### Frontend Prompt 1: Generate Types
**Copy this to Claude Code:**

```
Backend is complete. Generate TypeScript types:

cd frontend
npm run generate:types

Verify types exist in src/types/generated/api.ts:
- ProductResponse, ProductCreate, ProductUpdate
- CategoryResponse, CategoryCreate
- PricingTierResponse
- ProductImageResponse
- Permission enum includes PRODUCTS_* and CATEGORIES_MANAGE
```

### Frontend Prompt 2: API Integration
**Copy this to Claude Code:**

```
Create product API integration:

File: src/features/products/api/products.ts

Functions:
- getProducts(filters) - List with filters
- getProduct(id) - Single product
- createProduct(data) - Create
- updateProduct(id, data) - Update
- deleteProduct(id) - Delete
- uploadProductImage(productId, file, isPrimary) - Upload image
- deleteProductImage(productId, imageId) - Delete image

File: src/features/products/hooks/useProducts.ts

TanStack Query hooks:
- useProducts(filters) - Query for list
- useProduct(id) - Query for single
- useCreateProduct() - Mutation for create
- useUpdateProduct() - Mutation for update
- useDeleteProduct() - Mutation for delete
- useUploadProductImage() - Mutation for upload

Include proper cache invalidation on mutations.

Use /api-integration skill.
```

### Frontend Prompt 3: Product Components
**Copy this to Claude Code:**

```
Create product components:

1. ProductCard (src/features/products/components/ProductCard.tsx)
   - Display: image, name, price (with tiers if available), stock badge
   - Stock badge: green if > threshold, yellow if <= threshold, red if 0
   - Click navigates to product detail
   - Show edit/delete buttons if user has PRODUCTS_WRITE permission

2. ProductFilters (src/features/products/components/ProductFilters.tsx)
   - Category tree selector (from useCategories hook)
   - Price range slider (min/max inputs)
   - Search input (debounced)
   - "In Stock Only" checkbox
   - "Clear Filters" button

3. ImageGallery (src/features/products/components/ImageGallery.tsx)
   - Display product images with primary image first
   - Click to open lightbox/modal
   - If in edit mode, show delete buttons and primary selector

4. PricingTierTable (src/features/products/components/PricingTierTable.tsx)
   - Display tiers as table: Quantity | Price per Unit
   - If in edit mode, allow adding/removing tiers
   - Validate: min_quantity must be > 0 and unique

Use /react-component skill for each.
```

### Frontend Prompt 4: Product Form
**Copy this to Claude Code:**

```
Create ProductForm component (src/features/products/components/ProductForm.tsx):

Fields:
- name (required, max 200 chars)
- description (optional, textarea)
- sku (required, alphanumeric, unique)
- base_price (required, positive decimal, formatted as currency)
- stock_quantity (required, integer >= 0)
- low_stock_threshold (required, integer > 0)
- category (required, select from categories)
- pricing_tiers (optional, dynamic array of {min_quantity, price})
- images (file upload, multiple, show previews)

Validation with Zod matching backend schemas.
Handle create and edit modes.
On submit: createProduct or updateProduct mutation.

Use /react-form skill.
```

### Frontend Prompt 5: Product Pages
**Copy this to Claude Code:**

```
Create product pages:

1. ProductListPage (src/features/products/pages/ProductListPage.tsx)
   Route: /products
   - ProductFilters component
   - Grid of ProductCard components
   - Pagination
   - Loading skeleton
   - Empty state if no products
   - "Add Product" button (permission: PRODUCTS_WRITE) → opens ProductForm modal

2. ProductDetailPage (src/features/products/pages/ProductDetailPage.tsx)
   Route: /products/:id
   - ImageGallery
   - Product info (name, description, SKU, price)
   - PricingTierTable (read-only)
   - Stock badge
   - Category breadcrumb
   - Edit button (permission: PRODUCTS_WRITE) → opens ProductForm modal
   - Delete button (permission: PRODUCTS_DELETE) → confirmation dialog

3. AdminProductsPage (src/features/products/pages/AdminProductsPage.tsx)
   Route: /admin/products
   - Table view of products with inline edit/delete
   - Bulk actions (delete multiple)
   - Permission: PRODUCTS_WRITE (redirect if missing)

Add routes to router configuration with lazy loading.

Use /react-page skill.
```

### Frontend Prompt 6: Category Management
**Copy this to Claude Code:**

```
Create category management:

1. CategoryTree component (src/features/products/components/CategoryTree.tsx)
   - Display hierarchical category tree
   - Expand/collapse nodes
   - If in manage mode, show edit/delete/add child buttons
   - Drag-and-drop to reorder (update sort_order)

2. CategoryForm component (src/features/products/components/CategoryForm.tsx)
   - Fields: name, slug (auto-generated from name), parent (select from tree)
   - Validation: slug must be unique, URL-safe
   - Create/edit modes

3. AdminCategoriesPage (src/features/products/pages/AdminCategoriesPage.tsx)
   Route: /admin/categories
   - CategoryTree in manage mode
   - Permission: CATEGORIES_MANAGE

Use /react-component and /react-page skills.
```

## Testing Strategy

### Backend Tests
- [ ] Product CRUD operations work
- [ ] Filters (category, price, search, stock) work correctly
- [ ] Pricing tiers are created/updated with product
- [ ] Image upload handles validation (file type, size)
- [ ] Category tree structure is correct
- [ ] Permissions are enforced (non-admin cannot create/delete)
- [ ] Soft delete works (is_active = False, product still in DB)

### Frontend Tests (Manual)
- [ ] Product list loads and filters work
- [ ] Product detail shows all info correctly
- [ ] Product form validates input
- [ ] Image upload works and shows previews
- [ ] Category tree displays hierarchy correctly
- [ ] Permissions hide/show correct buttons
- [ ] Stock badges show correct colors
- [ ] Pricing tiers calculate correctly

### Integration Tests
- [ ] Create product via frontend → verify in backend DB
- [ ] Upload image → verify file saved and URL correct
- [ ] Delete product → verify soft deleted
- [ ] Filter by category → verify correct products returned

## Acceptance Criteria

- ✅ Admin can create products with multiple images and pricing tiers
- ✅ Admin can organize products into hierarchical categories
- ✅ Users can browse products and filter by category, price, availability
- ✅ Search works across product name, description, SKU
- ✅ Stock levels display with visual indicators
- ✅ Bulk pricing shows correct price per quantity tier
- ✅ Image gallery works with primary image first
- ✅ Permissions prevent non-admin from managing products
- ✅ All backend tests pass
- ✅ Type safety maintained (no `any` types in frontend)

## Potential Issues & Considerations

⚠️ **Image Storage**:
- Dev: Local filesystem (./uploads/)
- Prod: Migrate to S3/CloudFront (add env vars, update storage service)

⚠️ **Category Deletion**:
- Prevent if products assigned (show error)
- Option: Re-assign products to parent category before deleting

⚠️ **Pricing Tiers**:
- Frontend should sort by min_quantity ascending
- Validate no overlapping/duplicate quantities

⚠️ **Stock Management**:
- Current: Manual stock updates
- Future: Integrate with order system to auto-decrement

⚠️ **Search Performance**:
- Add full-text search index if product count > 10K
- Consider Elasticsearch for advanced search

## Next Steps

1. Copy Backend Prompts 1-7 to Claude Code and execute sequentially
2. Verify backend works: `docker compose exec backend pytest`
3. Generate types: `cd frontend && npm run generate:types`
4. Copy Frontend Prompts 1-6 to Claude Code and execute
5. Test feature manually in browser
6. Commit: `git add . && git commit -m "Add product catalog feature"`
```

**End of Claude.ai Project Response**

---

### Copy Prompts to Claude Code

1. Open Claude Code session
2. Copy "Backend Prompt 1" from above
3. Paste and execute
4. Wait for completion
5. Copy "Backend Prompt 2"
6. Repeat until all prompts executed
7. Test and commit

## Maintenance

### Update Knowledge Files

After adding new patterns or significant features:

1. Update relevant documentation files
2. Re-upload to Claude.ai Project (replaces old version)
3. Test that Claude references new patterns

**Example**:
```
# Added WebSocket support to backend
1. Update backend/docs/FEATURE_WORKFLOW.md with WebSocket section
2. Upload to Project (replaces old file)
3. Test: "Design a real-time notifications feature with WebSockets"
4. Verify Claude references the new WebSocket patterns
```

### Keep Project Aligned with Codebase

**Every ~2-3 major features**:
- Review uploaded docs for accuracy
- Add new example code files if patterns changed
- Update custom instructions if workflow changed

## Tips

### DO
- ✅ Use Projects for complex planning (3+ components, unclear approach)
- ✅ Upload comprehensive docs (CLAUDE.md, workflows, patterns)
- ✅ Generate numbered prompts for Claude Code
- ✅ Test prompts in Code before considering feature complete
- ✅ Update knowledge files when patterns evolve

### DON'T
- ❌ Use Project for simple tasks (just use Claude Code directly)
- ❌ Upload entire codebase (selective files only)
- ❌ Expect Project to execute code (it only plans)
- ❌ Skip testing prompts in Code
- ❌ Forget to update docs after major changes

### When to Skip Projects

**Use Claude Code Directly**:
- Simple features following established patterns
- Bug fixes with clear reproduction
- Documentation updates
- Single-component additions
- Tasks where you already know the approach

**Use Project First**:
- New architectural patterns
- Features touching 5+ files
- Complex business logic
- Unclear requirements (need design discussion)
- Integration with new external services

## Troubleshooting

### Claude Project Can't Find Pattern

**Problem**: "I don't see information about X in the knowledge files"

**Solution**:
1. Check file was uploaded (click "Content" in Project)
2. Verify file contains the pattern (might be in different file)
3. Upload missing file if needed
4. Explicitly reference: "See the pattern in backend/CLAUDE.md section on..."

### Prompts Don't Work in Claude Code

**Problem**: Prompt from Project doesn't work when pasted to Code

**Solution**:
1. Ensure backend is running (`docker compose up -d`)
2. Check prompt has all required context
3. May need to add file references (Code can't see Project knowledge)
4. Simplify prompt - might be too complex for single execution

### Project References Outdated Patterns

**Problem**: Project suggests old approach no longer used

**Solution**:
1. Update documentation files in codebase
2. Re-upload to Project
3. In Project chat: "Disregard previous approach, we now use..."
4. Consider starting new Project session for complex changes

## Next Steps

- **Set up your Project** → Follow "One-Time Setup" above
- **Test with a feature** → Try planning a simple feature
- **Use with Claude Code** → Execute generated prompts
- **Iterate** → Refine custom instructions based on results
- **Read workflow guide** → See `docs/FULLSTACK_WORKFLOW.md` for integration

---

**Related Documentation**:
- `CLAUDE_CODE_BEST_PRACTICES.md` - Two-stage workflow details (Section H)
- `docs/FULLSTACK_WORKFLOW.md` - E2E feature workflows
- `docs/ARCHITECTURE.md` - System architecture for planning context
