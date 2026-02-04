---
name: fullstack-feature
description: Create a complete CRUD feature from scratch with backend API, database models, frontend UI, authentication, and permissions. Use for greenfield features where nothing exists yet. Most comprehensive skill covering complete fullstack implementation with PostgreSQL or MongoDB, all layers (models, repositories, services, endpoints, tests), type generation, frontend components, pages, routes, and i18n.
---

# Fullstack Feature Implementation

Create a complete CRUD feature from scratch: backend API with database models, repositories, services, endpoints, and tests; type generation; frontend UI with API integration, components, pages, routes, and i18n. This is the most comprehensive workflow for greenfield features.

## When to Use This Skill

- ✅ Creating a brand new feature from scratch
- ✅ Need both backend and frontend implementation
- ✅ Want complete CRUD operations (Create, Read, Update, Delete)
- ✅ Need proper auth and permissions
- ✅ Want production-ready code with tests

**Don't use when**:
- Backend already exists → Use `/api-to-ui` skill
- Just need backend OR frontend → Use `/backend-first` or layer-specific skills

## Prerequisites

```bash
# Verify services running
docker compose ps

# Start if needed
docker compose up -d

# Verify backend accessible
curl http://localhost:8000/docs

# Verify frontend accessible
curl http://localhost:5173
```

## Workflow Overview

5 Major Phases:

1. **Planning** - Requirements, database choice, architecture decisions
2. **Backend** - Models, repos, services, endpoints, tests, migrations
3. **Type Generation** - OpenAPI → TypeScript types
4. **Frontend** - API, hooks, schemas, components, pages, routes, i18n
5. **Integration Testing** - E2E verification

Estimated time: 30-90 minutes depending on complexity

## Phase 1: Planning & Requirements

### Step 1.1: Feature Overview

Ask the user:

1. **Feature name**: What are you building? (e.g., "products", "orders", "blog-posts")
2. **Description**: What does this feature do? (brief summary)
3. **Complexity**: Simple CRUD, moderate (with relationships), or complex (multiple related entities)?

### Step 1.2: Data Requirements

Ask the user:

**Fields needed**:
- What fields does the main entity have?
- What are the data types? (string, number, boolean, date, UUID, etc.)
- Which fields are required vs optional?
- Any special validation? (min/max length, regex patterns, etc.)
- Any unique constraints? (email, SKU, slug, etc.)

**Example**:
```
Product:
- name (string, required, max 200 chars)
- description (string, optional)
- sku (string, required, unique, max 50 chars)
- price (decimal, required, positive, 2 decimal places)
- stock_quantity (integer, required, >= 0)
- is_active (boolean, default true)
- category_id (UUID, optional, FK to categories)
```

### Step 1.3: Database Choice Decision

Ask about data characteristics to choose database:

#### Decision Tree

```
Does the data have:
├─ Fixed structure with relationships?
│  └─ Use PostgreSQL ✅
│
├─ Flexible/evolving schema?
│  └─ Use MongoDB ✅
│
├─ Mix of both (structured + flexible)?
│  └─ Use BOTH ✅
│     - PostgreSQL for core entities
│     - MongoDB for logs, events, metadata
│
└─ High write volume (logs, analytics)?
   └─ Use MongoDB ✅
```

#### PostgreSQL - Best For

- ✅ User management, authentication
- ✅ Roles and permissions (RBAC)
- ✅ Transactional data (orders, payments)
- ✅ Data with relationships (products → categories)
- ✅ Data requiring ACID guarantees
- ✅ Complex queries with JOINs

**Choose PostgreSQL when**: Structured data, relationships, transactions

#### MongoDB - Best For

- ✅ Event logs and audit trails
- ✅ Analytics and metrics data
- ✅ Flexible schemas (varying structure)
- ✅ High write throughput
- ✅ Nested/hierarchical data (comments tree)
- ✅ Temporary/cache data

**Choose MongoDB when**: Flexible schema, high writes, nested data

#### Both - Best For

- ✅ Core data in PostgreSQL (users, products)
- ✅ Activity logs in MongoDB (user actions, events)
- ✅ Product catalog in PostgreSQL
- ✅ Product reviews in MongoDB (flexible metadata)

### Step 1.4: Relationships

Ask the user:

- Does this entity relate to others?
- What's the relationship type? (one-to-many, many-to-many)
- Should deletions cascade or be prevented?

**Examples**:
- Product → Category (many-to-one)
- User → Orders (one-to-many)
- Products ↔ Tags (many-to-many via junction table)

### Step 1.5: Permissions

Ask the user what permissions are needed:

**Standard CRUD pattern**:
- `{FEATURE}_READ` - View/list items
- `{FEATURE}_WRITE` - Create and update items
- `{FEATURE}_DELETE` - Delete items

**Example**:
- `PRODUCTS_READ` - Anyone can view products
- `PRODUCTS_WRITE` - Only admins can create/edit
- `PRODUCTS_DELETE` - Only owners can delete

**Which roles need which permissions?**
- Admin role: All permissions
- User role: READ only
- Manager role: READ + WRITE

### Step 1.6: UI Requirements

Ask the user:

1. **List view**: Yes/no, pagination needed?
2. **Detail view**: Separate page or modal?
3. **Create**: Modal or page?
4. **Edit**: Inline, modal, or page?
5. **Delete**: Confirmation dialog?
6. **Search/filter**: Needed? By which fields?
7. **Bulk actions**: Delete multiple, export, etc.?

### Step 1.7: Create Implementation Plan

Based on answers, create a mental plan:

**Simple Feature** (e.g., tags):
- PostgreSQL: Single table, no relationships
- Permissions: READ (all), WRITE/DELETE (admin)
- UI: Simple list + create modal

**Moderate Feature** (e.g., products):
- PostgreSQL: Main table + relationship to categories
- Permissions: READ (all), WRITE/DELETE (admin)
- UI: List with search, detail page, create/edit forms

**Complex Feature** (e.g., orders with items):
- PostgreSQL: Orders table + OrderItems junction
- Permissions: Multiple (create own, read own vs all, admin actions)
- UI: List, detail with nested items, multi-step creation wizard

## Phase 2: Backend Implementation

Work in `backend/` directory for all backend steps.

### Step 2.1: Create Model

#### For PostgreSQL

Create `backend/app/models/{feature}.py`:

```python
from sqlalchemy import String, Text, Decimal, Integer, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base
from uuid import UUID, uuid4
from datetime import datetime

class Product(Base):
    """Product model for catalog management."""
    __tablename__ = "products"

    # Primary key (inherited from Base but shown for clarity)
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)

    # Required fields
    name: Mapped[str] = mapped_column(String(200), index=True)
    sku: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    price: Mapped[Decimal] = mapped_column(Decimal(10, 2))
    stock_quantity: Mapped[int] = mapped_column(Integer, default=0)

    # Optional fields
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Boolean flags
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Foreign keys
    category_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL"),
        nullable=True
    )

    # Relationships
    category: Mapped["Category"] = relationship(back_populates="products")

    # Timestamps (inherited from Base)
    created_at: Mapped[datetime]
    updated_at: Mapped[datetime]
    created_by_id: Mapped[UUID | None]  # If tracking who created

    def __repr__(self) -> str:
        return f"<Product(id={self.id}, name={self.name})>"
```

**Model conventions**:
- Use `Mapped[]` type hints
- Add docstring describing purpose
- Include `__repr__` for debugging
- Use proper SQLAlchemy types: `String`, `Text`, `Decimal`, `Integer`, `Boolean`, `DateTime`
- Add indexes on frequently queried fields
- Use `unique=True` for unique constraints
- Use `nullable=True` for optional fields
- Define `ondelete` behavior for foreign keys
- Use `back_populates` for bidirectional relationships

#### For MongoDB

Create `backend/app/models/mongodb/{feature}.py`:

```python
from beanie import Document
from pydantic import Field
from datetime import datetime
from uuid import UUID, uuid4

class Event(Document):
    """Event log document for analytics."""

    # Fields
    event_type: str = Field(..., max_length=100)
    user_id: UUID
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    metadata: dict = Field(default_factory=dict)  # Flexible field

    # Index configuration
    class Settings:
        name = "events"  # Collection name
        indexes = [
            "event_type",
            "user_id",
            "timestamp",
        ]

    def __repr__(self) -> str:
        return f"<Event(type={self.event_type}, user={self.user_id})>"
```

Register in `backend/app/db/mongodb.py`:

```python
from app.models.mongodb.event import Event

document_models = [
    Event,
    # ... other models
]
```

### Step 2.2: Create Migration (PostgreSQL only)

Generate migration:

```bash
cd backend

# Auto-generate migration from model changes
alembic revision --autogenerate -m "Add {feature} model"

# Review generated migration in app/alembic/versions/
# Check: columns, indexes, foreign keys, constraints

# Apply migration
alembic upgrade head

# Verify
alembic current
```

**Review checklist**:
- [ ] All columns created with correct types
- [ ] Indexes added for frequently queried fields
- [ ] Foreign keys reference correct tables with proper ondelete
- [ ] Unique constraints applied where needed
- [ ] Default values set correctly

If migration looks wrong, edit manually or delete and regenerate.

### Step 2.3: Add Permissions

Update `backend/app/models/permission.py`:

```python
class Permission(str, Enum):
    # ... existing permissions

    # New feature permissions
    PRODUCTS_READ = "products:read"
    PRODUCTS_WRITE = "products:write"
    PRODUCTS_DELETE = "products:delete"
```

Create migration to insert permissions:

```bash
alembic revision -m "Add {feature} permissions"
```

Edit the migration file:

```python
from alembic import op

def upgrade():
    op.execute("""
        INSERT INTO permissions (name, description)
        VALUES
            ('products:read', 'View products'),
            ('products:write', 'Create and update products'),
            ('products:delete', 'Delete products')
        ON CONFLICT (name) DO NOTHING;
    """)

    # Optionally assign to roles
    op.execute("""
        INSERT INTO role_permissions (role_id, permission_id)
        SELECT r.id, p.id
        FROM roles r, permissions p
        WHERE r.name = 'admin'
        AND p.name IN ('products:read', 'products:write', 'products:delete')
        ON CONFLICT DO NOTHING;
    """)

def downgrade():
    op.execute("""
        DELETE FROM permissions
        WHERE name IN ('products:read', 'products:write', 'products:delete');
    """)
```

Apply migration:

```bash
alembic upgrade head
```

### Step 2.4: Create Schemas

Create `backend/app/schemas/{feature}.py`:

```python
from pydantic import BaseModel, Field, field_validator
from uuid import UUID
from datetime import datetime
from decimal import Decimal

class ProductBase(BaseModel):
    """Shared fields for Product."""
    name: str = Field(..., min_length=1, max_length=200)
    description: str | None = Field(None, max_length=1000)
    sku: str = Field(..., min_length=1, max_length=50)
    price: Decimal = Field(..., gt=0, decimal_places=2)
    stock_quantity: int = Field(..., ge=0)
    category_id: UUID | None = None

    @field_validator('sku')
    @classmethod
    def validate_sku(cls, v: str) -> str:
        """Ensure SKU is uppercase and alphanumeric."""
        if not v.replace('-', '').isalnum():
            raise ValueError('SKU must be alphanumeric')
        return v.upper()

class ProductCreate(ProductBase):
    """Schema for creating a product."""
    pass

class ProductUpdate(BaseModel):
    """Schema for updating a product (all fields optional)."""
    name: str | None = Field(None, min_length=1, max_length=200)
    description: str | None = None
    sku: str | None = Field(None, min_length=1, max_length=50)
    price: Decimal | None = Field(None, gt=0)
    stock_quantity: int | None = Field(None, ge=0)
    category_id: UUID | None = None
    is_active: bool | None = None

class ProductResponse(ProductBase):
    """Schema for product responses."""
    id: UUID
    is_active: bool
    created_at: datetime
    updated_at: datetime
    created_by_id: UUID | None

    class Config:
        from_attributes = True  # Enable ORM mode

class ProductListResponse(BaseModel):
    """Schema for paginated product list."""
    items: list[ProductResponse]
    total: int
    page: int
    size: int
    pages: int
```

**Schema conventions**:
- `Base` - Shared fields
- `Create` - Fields required for creation
- `Update` - All fields optional (partial updates)
- `Response` - Includes computed fields, timestamps, IDs
- `ListResponse` - Paginated response wrapper
- Use `Field()` for validation
- Add `field_validator` for custom validation
- Enable `from_attributes = True` for ORM mode

### Step 2.5: Create Repository

Create `backend/app/repositories/{feature}_repository.py`:

```python
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func
from sqlalchemy.orm import selectinload
from app.models.{feature} import Product
from uuid import UUID

class ProductRepository:
    """Repository for Product database operations."""

    def __init__(self, session: AsyncSession):
        self.session = session

    async def get(self, product_id: UUID) -> Product | None:
        """Get product by ID."""
        result = await self.session.execute(
            select(Product)
            .where(Product.id == product_id)
            .options(selectinload(Product.category))  # Eager load relationship
        )
        return result.scalar_one_or_none()

    async def get_paginated(
        self,
        offset: int = 0,
        limit: int = 10,
        filters: dict | None = None,
        sort_by: str = "created_at",
        order: str = "desc"
    ) -> list[Product]:
        """Get paginated list of products with filtering."""
        query = select(Product).where(Product.is_active == True)

        # Apply filters
        if filters:
            if "category_id" in filters and filters["category_id"]:
                query = query.where(Product.category_id == filters["category_id"])

            if "search" in filters and filters["search"]:
                search_term = f"%{filters['search']}%"
                query = query.where(
                    (Product.name.ilike(search_term)) |
                    (Product.sku.ilike(search_term))
                )

            if "min_price" in filters and filters["min_price"]:
                query = query.where(Product.price >= filters["min_price"])

            if "max_price" in filters and filters["max_price"]:
                query = query.where(Product.price <= filters["max_price"])

            if "in_stock" in filters and filters["in_stock"]:
                query = query.where(Product.stock_quantity > 0)

        # Apply sorting
        sort_column = getattr(Product, sort_by, Product.created_at)
        if order == "desc":
            query = query.order_by(sort_column.desc())
        else:
            query = query.order_by(sort_column.asc())

        # Apply pagination
        query = query.offset(offset).limit(limit)

        # Eager load relationships
        query = query.options(selectinload(Product.category))

        result = await self.session.execute(query)
        return result.scalars().all()

    async def count(self, filters: dict | None = None) -> int:
        """Count total products matching filters."""
        query = select(func.count(Product.id)).where(Product.is_active == True)

        # Apply same filters as get_paginated
        if filters:
            if "category_id" in filters and filters["category_id"]:
                query = query.where(Product.category_id == filters["category_id"])
            if "search" in filters and filters["search"]:
                search_term = f"%{filters['search']}%"
                query = query.where(
                    (Product.name.ilike(search_term)) |
                    (Product.sku.ilike(search_term))
                )
            if "min_price" in filters and filters["min_price"]:
                query = query.where(Product.price >= filters["min_price"])
            if "max_price" in filters and filters["max_price"]:
                query = query.where(Product.price <= filters["max_price"])
            if "in_stock" in filters and filters["in_stock"]:
                query = query.where(Product.stock_quantity > 0)

        result = await self.session.execute(query)
        return result.scalar_one()

    async def create(self, product: Product) -> Product:
        """Create a new product."""
        self.session.add(product)
        await self.session.commit()
        await self.session.refresh(product)
        return product

    async def update(self, product_id: UUID, data: dict) -> Product | None:
        """Update product by ID."""
        await self.session.execute(
            update(Product)
            .where(Product.id == product_id)
            .values(**data, updated_at=func.now())
        )
        await self.session.commit()
        return await self.get(product_id)

    async def delete(self, product_id: UUID) -> bool:
        """Soft delete product (set is_active=False)."""
        result = await self.session.execute(
            update(Product)
            .where(Product.id == product_id)
            .values(is_active=False, updated_at=func.now())
        )
        await self.session.commit()
        return result.rowcount > 0

    async def hard_delete(self, product_id: UUID) -> bool:
        """Hard delete product from database."""
        result = await self.session.execute(
            delete(Product).where(Product.id == product_id)
        )
        await self.session.commit()
        return result.rowcount > 0
```

**Repository conventions**:
- Take `AsyncSession` in constructor
- Return model instances or None
- Use `scalar_one_or_none()` for single results
- Use `scalars().all()` for lists
- Implement pagination with offset/limit
- Add filtering capabilities
- Use soft delete by default (`is_active=False`)
- Provide `hard_delete` if needed
- Use `selectinload()` for eager loading relationships
- Update `updated_at` on modifications

### Step 2.6: Create Service

Create `backend/app/services/{feature}_service.py`:

```python
from app.repositories.{feature}_repository import ProductRepository
from app.schemas.{feature} import ProductCreate, ProductUpdate, ProductListResponse
from app.models.{feature} import Product
from uuid import UUID

class ProductService:
    """Service for product business logic."""

    def __init__(self, repository: ProductRepository):
        self.repository = repository

    async def get_product(self, product_id: UUID) -> Product | None:
        """Get product by ID."""
        return await self.repository.get(product_id)

    async def list_products(
        self,
        page: int = 1,
        size: int = 10,
        filters: dict | None = None,
        sort_by: str = "created_at",
        order: str = "desc"
    ) -> ProductListResponse:
        """Get paginated list of products."""
        offset = (page - 1) * size

        products = await self.repository.get_paginated(
            offset=offset,
            limit=size,
            filters=filters,
            sort_by=sort_by,
            order=order
        )

        total = await self.repository.count(filters=filters)

        return ProductListResponse(
            items=products,
            total=total,
            page=page,
            size=size,
            pages=(total + size - 1) // size
        )

    async def create_product(self, data: ProductCreate, created_by_id: UUID | None = None) -> Product:
        """Create a new product."""
        product = Product(
            **data.model_dump(),
            created_by_id=created_by_id
        )
        return await self.repository.create(product)

    async def update_product(
        self,
        product_id: UUID,
        data: ProductUpdate
    ) -> Product | None:
        """Update an existing product."""
        # Only update fields that were provided
        update_data = data.model_dump(exclude_unset=True)

        if not update_data:
            # No fields to update, return current product
            return await self.repository.get(product_id)

        return await self.repository.update(product_id, update_data)

    async def delete_product(self, product_id: UUID) -> bool:
        """Delete a product (soft delete)."""
        return await self.repository.delete(product_id)

    async def check_sku_exists(self, sku: str, exclude_id: UUID | None = None) -> bool:
        """Check if SKU already exists (for validation)."""
        # Implementation depends on your needs
        # This is a placeholder for business logic
        return False
```

**Service conventions**:
- Take repository in constructor
- Implement business logic
- Handle validation that spans multiple entities
- Convert between schemas and models
- Calculate pagination details
- Don't handle HTTP concerns (that's in routes)
- Return models, not schemas

### Step 2.7: Create API Endpoints

Create `backend/app/api/v1/endpoints/{feature}.py`:

```python
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.schemas.{feature} import (
    ProductCreate,
    ProductUpdate,
    ProductResponse,
    ProductListResponse
)
from app.services.{feature}_service import ProductService
from app.repositories.{feature}_repository import ProductRepository
from app.common.dependencies import get_current_user, require_permissions
from app.models.permission import Permission
from app.models.user import User
from uuid import UUID

router = APIRouter(prefix="/products", tags=["products"])

def get_product_service(db: AsyncSession = Depends(get_db)) -> ProductService:
    """Dependency to get product service."""
    repository = ProductRepository(db)
    return ProductService(repository)

@router.get("", response_model=ProductListResponse)
@require_permissions(Permission.PRODUCTS_READ)
async def list_products(
    page: int = Query(1, ge=1),
    size: int = Query(10, ge=1, le=100),
    search: str | None = None,
    category_id: UUID | None = None,
    min_price: float | None = None,
    max_price: float | None = None,
    in_stock: bool | None = None,
    sort_by: str = Query("created_at", regex="^(name|price|created_at|stock_quantity)$"),
    order: str = Query("desc", regex="^(asc|desc)$"),
    service: ProductService = Depends(get_product_service),
    current_user: User = Depends(get_current_user)
):
    """
    List products with pagination and filtering.

    - **page**: Page number (starts at 1)
    - **size**: Items per page (max 100)
    - **search**: Search in name and SKU
    - **category_id**: Filter by category
    - **min_price/max_price**: Price range filter
    - **in_stock**: Only show items in stock
    - **sort_by**: Sort field
    - **order**: Sort order (asc/desc)
    """
    filters = {}
    if search:
        filters["search"] = search
    if category_id:
        filters["category_id"] = category_id
    if min_price is not None:
        filters["min_price"] = min_price
    if max_price is not None:
        filters["max_price"] = max_price
    if in_stock is not None:
        filters["in_stock"] = in_stock

    return await service.list_products(
        page=page,
        size=size,
        filters=filters,
        sort_by=sort_by,
        order=order
    )

@router.get("/{product_id}", response_model=ProductResponse)
@require_permissions(Permission.PRODUCTS_READ)
async def get_product(
    product_id: UUID,
    service: ProductService = Depends(get_product_service),
    current_user: User = Depends(get_current_user)
):
    """Get a single product by ID."""
    product = await service.get_product(product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with ID {product_id} not found"
        )
    return product

@router.post("", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
@require_permissions(Permission.PRODUCTS_WRITE)
async def create_product(
    data: ProductCreate,
    service: ProductService = Depends(get_product_service),
    current_user: User = Depends(get_current_user)
):
    """Create a new product."""
    return await service.create_product(data, created_by_id=current_user.id)

@router.put("/{product_id}", response_model=ProductResponse)
@require_permissions(Permission.PRODUCTS_WRITE)
async def update_product(
    product_id: UUID,
    data: ProductUpdate,
    service: ProductService = Depends(get_product_service),
    current_user: User = Depends(get_current_user)
):
    """Update an existing product."""
    product = await service.update_product(product_id, data)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with ID {product_id} not found"
        )
    return product

@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
@require_permissions(Permission.PRODUCTS_DELETE)
async def delete_product(
    product_id: UUID,
    service: ProductService = Depends(get_product_service),
    current_user: User = Depends(get_current_user)
):
    """Delete a product (soft delete)."""
    deleted = await service.delete_product(product_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with ID {product_id} not found"
        )
```

**Register router** in `backend/app/api/v1/api.py`:

```python
from app.api.v1.endpoints import products

api_router.include_router(products.router)
```

**Endpoint conventions**:
- Use FastAPI dependency injection
- Apply `@require_permissions()` decorator
- Use `Query()` for query parameters with validation
- Return proper status codes (200, 201, 204, 404)
- Raise `HTTPException` with detail messages
- Use proper response models
- Include docstrings describing endpoint behavior
- Validate sort fields with regex
- Limit page size to prevent abuse

### Step 2.8: Write Tests

Create `backend/tests/integration/test_{feature}.py`:

```python
import pytest
from httpx import AsyncClient
from uuid import uuid4

@pytest.mark.asyncio
async def test_create_product(client: AsyncClient, admin_headers: dict):
    """Test creating a product."""
    response = await client.post(
        "/api/v1/products",
        json={
            "name": "Test Product",
            "sku": "TEST-001",
            "price": 29.99,
            "stock_quantity": 100,
            "description": "A test product"
        },
        headers=admin_headers
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Test Product"
    assert data["sku"] == "TEST-001"
    assert data["is_active"] is True
    assert "id" in data
    assert "created_at" in data

@pytest.mark.asyncio
async def test_list_products(client: AsyncClient, admin_headers: dict):
    """Test listing products with pagination."""
    response = await client.get(
        "/api/v1/products?page=1&size=10",
        headers=admin_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert "page" in data
    assert "size" in data
    assert "pages" in data
    assert isinstance(data["items"], list)

@pytest.mark.asyncio
async def test_get_product(client: AsyncClient, admin_headers: dict, product_id: str):
    """Test getting a single product."""
    response = await client.get(
        f"/api/v1/products/{product_id}",
        headers=admin_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == product_id

@pytest.mark.asyncio
async def test_get_product_not_found(client: AsyncClient, admin_headers: dict):
    """Test getting a non-existent product returns 404."""
    fake_id = str(uuid4())
    response = await client.get(
        f"/api/v1/products/{fake_id}",
        headers=admin_headers
    )
    assert response.status_code == 404

@pytest.mark.asyncio
async def test_update_product(client: AsyncClient, admin_headers: dict, product_id: str):
    """Test updating a product."""
    response = await client.put(
        f"/api/v1/products/{product_id}",
        json={"price": 39.99, "stock_quantity": 50},
        headers=admin_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert data["price"] == 39.99
    assert data["stock_quantity"] == 50

@pytest.mark.asyncio
async def test_delete_product(client: AsyncClient, admin_headers: dict, product_id: str):
    """Test deleting a product."""
    response = await client.delete(
        f"/api/v1/products/{product_id}",
        headers=admin_headers
    )
    assert response.status_code == 204

    # Verify product is soft deleted (not accessible)
    response = await client.get(
        f"/api/v1/products/{product_id}",
        headers=admin_headers
    )
    assert response.status_code == 404

@pytest.mark.asyncio
async def test_list_products_with_search(client: AsyncClient, admin_headers: dict):
    """Test searching products."""
    response = await client.get(
        "/api/v1/products?search=test",
        headers=admin_headers
    )
    assert response.status_code == 200
    data = response.json()
    # All returned items should match search
    for item in data["items"]:
        assert "test" in item["name"].lower() or "test" in item["sku"].lower()

@pytest.mark.asyncio
async def test_permission_check_read(client: AsyncClient, user_headers: dict):
    """Test that users without PRODUCTS_WRITE cannot create products."""
    response = await client.post(
        "/api/v1/products",
        json={
            "name": "Test",
            "sku": "TEST",
            "price": 10.00,
            "stock_quantity": 1
        },
        headers=user_headers
    )
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_validation_errors(client: AsyncClient, admin_headers: dict):
    """Test validation errors for invalid data."""
    # Missing required field
    response = await client.post(
        "/api/v1/products",
        json={"name": "Test"},  # Missing sku, price, stock_quantity
        headers=admin_headers
    )
    assert response.status_code == 422

    # Invalid price (negative)
    response = await client.post(
        "/api/v1/products",
        json={
            "name": "Test",
            "sku": "TEST",
            "price": -10.00,  # Invalid
            "stock_quantity": 1
        },
        headers=admin_headers
    )
    assert response.status_code == 422
```

**Run tests**:

```bash
cd backend
pytest tests/integration/test_{feature}.py -v
```

## Phase 3: Type Generation

### Step 3.1: Verify Backend Running

```bash
# Check backend is accessible
curl http://localhost:8000/docs

# Check OpenAPI schema is valid
curl http://localhost:8000/openapi.json | jq '.components.schemas' | grep -A 5 "{Feature}"
```

### Step 3.2: Generate Types

```bash
cd frontend
npm run generate:types
```

This command:
1. Fetches http://localhost:8000/openapi.json
2. Generates TypeScript interfaces in `src/types/generated/api.ts`
3. Creates Permission enum with new permissions

### Step 3.3: Verify Types

```bash
# Check feature types exist
grep -A 10 "export interface ProductResponse" frontend/src/types/generated/api.ts

# Check permissions
grep "PRODUCTS_READ\|PRODUCTS_WRITE\|PRODUCTS_DELETE" frontend/src/types/generated/api.ts
```

**If types missing**: Check backend endpoint has `response_model` parameter.

## Phase 4: Frontend Implementation

Work in `frontend/` directory for all frontend steps.

### Step 4.1: Create Feature Structure

```bash
cd frontend/src/features
mkdir -p {feature}/{api,hooks,schemas,components,pages}
```

### Step 4.2: Create API Functions

Create `frontend/src/features/{feature}/api/{feature}.ts`:

```typescript
import { apiClient } from '@/lib/api-client';
import type {
  ProductResponse,
  ProductCreate,
  ProductUpdate,
  ProductListResponse
} from '@/types/generated/api';

export const getProducts = async (params?: {
  page?: number;
  size?: number;
  search?: string;
  category_id?: string;
  min_price?: number;
  max_price?: number;
  in_stock?: boolean;
  sort_by?: string;
  order?: 'asc' | 'desc';
}): Promise<ProductListResponse> => {
  const { data } = await apiClient.get('/products', { params });
  return data;
};

export const getProduct = async (id: string): Promise<ProductResponse> => {
  const { data } = await apiClient.get(`/products/${id}`);
  return data;
};

export const createProduct = async (
  product: ProductCreate
): Promise<ProductResponse> => {
  const { data } = await apiClient.post('/products', product);
  return data;
};

export const updateProduct = async (
  id: string,
  product: ProductUpdate
): Promise<ProductResponse> => {
  const { data } = await apiClient.put(`/products/${id}`, product);
  return data;
};

export const deleteProduct = async (id: string): Promise<void> => {
  await apiClient.delete(`/products/${id}`);
};
```

### Step 4.3: Create React Query Hooks

Create `frontend/src/features/{feature}/hooks/use{Feature}.ts`:

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { useTranslation } from 'react-i18next';
import {
  getProducts,
  getProduct,
  createProduct,
  updateProduct,
  deleteProduct
} from '../api/products';
import type { ProductCreate, ProductUpdate } from '@/types/generated/api';

export const useProducts = (filters?: {
  page?: number;
  size?: number;
  search?: string;
  category_id?: string;
  min_price?: number;
  max_price?: number;
  in_stock?: boolean;
  sort_by?: string;
  order?: 'asc' | 'desc';
}) => {
  return useQuery({
    queryKey: ['products', filters],
    queryFn: () => getProducts(filters),
    placeholderData: (prev) => prev,
  });
};

export const useProduct = (id: string | undefined) => {
  return useQuery({
    queryKey: ['products', id],
    queryFn: () => getProduct(id!),
    enabled: !!id,
  });
};

export const useCreateProduct = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: ProductCreate) => createProduct(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      toast.success(t('products.messages.createSuccess'));
    },
  });
};

export const useUpdateProduct = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: ProductUpdate }) =>
      updateProduct(id, data),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['products', variables.id] });
      toast.success(t('products.messages.updateSuccess'));
    },
  });
};

export const useDeleteProduct = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deleteProduct(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      toast.success(t('products.messages.deleteSuccess'));
    },
  });
};
```

### Step 4.4: Create Zod Schemas

Create `frontend/src/features/{feature}/schemas/{feature}.ts`:

```typescript
import { z } from 'zod';

export const productSchema = z.object({
  name: z.string().min(1, 'Name is required').max(200, 'Name is too long'),
  description: z.string().max(1000, 'Description is too long').optional(),
  sku: z.string().min(1, 'SKU is required').max(50, 'SKU is too long'),
  price: z.number().positive('Price must be positive'),
  stock_quantity: z.number().int().min(0, 'Stock cannot be negative'),
  category_id: z.string().uuid().optional(),
});

export type ProductFormData = z.infer<typeof productSchema>;
```

### Step 4.5: Create Components

**(See api-to-ui skill SKILL.md sections 5.1-5.3 for complete component implementations)**

Create:
- `ProductCard.tsx` - Display item in card format
- `ProductForm.tsx` - Create/edit form with validation
- `ProductList.tsx` - Display list with loading/error/empty states

### Step 4.6: Create Pages

**(See api-to-ui skill SKILL.md section 6 for complete page implementations)**

Create:
- `ProductListPage.tsx` - List with search, filter, pagination, create dialog
- `ProductDetailPage.tsx` (optional) - Detail view with edit/delete

### Step 4.7: Add Routes

**(See api-to-ui skill SKILL.md section 6.3 for route implementation)**

Add routes to `frontend/src/routes/`.

### Step 4.8: Add Translations

**(See api-to-ui skill SKILL.md section 7 for translation implementation)**

Add i18n keys to:
- `frontend/src/locales/en/translation.json`
- `frontend/src/locales/es/translation.json`

## Phase 5: Integration Testing

### Step 5.1: Backend Tests

```bash
cd backend
pytest tests/integration/test_{feature}.py -v

# All tests should pass ✅
```

### Step 5.2: Start Services

```bash
# Ensure both running
docker compose ps

# View logs if needed
docker compose logs -f backend frontend
```

### Step 5.3: Manual Browser Testing

1. **Navigate to list page**: http://localhost:5173/{feature}
2. **Test list view**:
   - Products load correctly
   - Pagination works
   - Search works
   - Filters work
   - Loading states display

3. **Test permissions**:
   - Login as admin → All buttons visible
   - Login as user → Only read access

4. **Test create**:
   - Click "Add" button
   - Fill form with valid data
   - Submit → Success toast
   - Item appears in list

5. **Test update**:
   - Click "Edit" on item
   - Modify fields
   - Submit → Success toast
   - Changes reflect immediately

6. **Test delete**:
   - Click "Delete" on item
   - Confirm dialog appears
   - Confirm → Success toast
   - Item removed from list

7. **Test validation**:
   - Try submit empty form → Validation errors
   - Try invalid data → Errors display

8. **Test error handling**:
   - Stop backend: `docker compose stop backend`
   - Try action → Error message displays
   - Start backend → Verify recovery

### Step 5.4: Integration Checklist

- [ ] Backend tests pass (pytest)
- [ ] Types generated correctly
- [ ] List page loads data
- [ ] Pagination works
- [ ] Search/filters work
- [ ] Create form works
- [ ] Update form works
- [ ] Delete with confirmation works
- [ ] Permission checks work (admin vs user)
- [ ] Loading states display correctly
- [ ] Error states display correctly
- [ ] Empty state displays
- [ ] Success toasts appear
- [ ] i18n works (switch language)
- [ ] Data refreshes after mutations

## Completion

### Final Steps

1. **Run all tests**:
```bash
cd backend && pytest
cd ../frontend && npm test  # if tests exist
```

2. **Code review**:
- Review generated code
- Check for TODO comments
- Verify naming conventions

3. **Commit**:
```bash
git add backend/app/models/{feature}.py \
        backend/app/schemas/{feature}.py \
        backend/app/repositories/{feature}_repository.py \
        backend/app/services/{feature}_service.py \
        backend/app/api/v1/endpoints/{feature}.py \
        backend/tests/integration/test_{feature}.py \
        backend/app/alembic/versions/*.py \
        frontend/src/features/{feature}/ \
        frontend/src/routes/{feature}.tsx \
        frontend/src/types/generated/api.ts \
        frontend/src/locales/*/translation.json

git commit -m "feat: Add {feature} complete CRUD feature

Backend:
- PostgreSQL model with relationships
- Repository with filtering and pagination
- Service with business logic
- CRUD endpoints with permissions
- Comprehensive test suite
- Alembic migrations

Frontend:
- API integration with React Query
- Zod validation schemas
- Components (Card, Form, List)
- Pages with routing
- Permission checks
- i18n (English + Spanish)

Permissions:
- {FEATURE}_READ (all users)
- {FEATURE}_WRITE (admins)
- {FEATURE}_DELETE (admins)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

## Troubleshooting

**(See backend-first and api-to-ui skills for detailed troubleshooting)**

Common issues:
- Migration fails → Check model definitions
- Types not generated → Verify backend running and OpenAPI valid
- 401/403 errors → Check permissions assigned to roles
- Components not styled → Verify shadcn/ui installed
- i18n not working → Check keys match in translation files

## Reference Documentation

- **Backend patterns**: `backend/docs/prompts/backend-patterns.md`
- **Frontend patterns**: `frontend/docs/prompts/frontend-patterns.md`
- **Integration patterns**: `docs/prompts/integration-patterns.md`
- **Full workflow**: `docs/FULLSTACK_WORKFLOW.md`
- **Architecture**: `docs/ARCHITECTURE.md`

## Success Criteria

✅ Backend:
- Model created with proper relationships
- Migration applied successfully
- Permissions added and assigned to roles
- All CRUD endpoints working
- Tests passing (100% coverage of endpoints)

✅ Frontend:
- Types generated from OpenAPI
- API functions using generated types
- React Query hooks implemented
- All components created (Card, Form, List)
- Pages created with routing
- Permission checks working
- i18n translations added

✅ Integration:
- End-to-end flow works
- Auth and permissions enforced
- Error handling working
- Loading states correct
- Data refreshes after mutations
- No console errors

**The feature is production-ready!** 🚀
