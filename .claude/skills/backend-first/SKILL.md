---
name: backend-first
description: Implement a complete fullstack feature using the backend-first workflow (recommended approach for data-driven features). Use when adding CRUD resources, dashboards, reports, or any feature requiring database design. Guides through backend implementation (models, migrations, endpoints, tests), type generation, and frontend integration (API hooks, components, pages). Ensures type safety and proper integration between backend and frontend.
---

# Backend-First Feature Implementation

Implement a complete fullstack feature following the backend-first workflow: define data models and API first, generate types, then build frontend UI. This is the recommended approach for data-driven features.

## When to Use This Skill

- ✅ Adding CRUD resources (products, orders, users, etc.)
- ✅ Data-driven features (dashboards, reports, analytics)
- ✅ Features requiring complex database design
- ✅ Features with clear data requirements upfront
- ✅ Features needing multiple frontend consumers

## Prerequisites Check

Before starting, verify:

```bash
# Services running
docker compose ps

# Backend accessible
curl http://localhost:8000/docs

# Frontend accessible
curl http://localhost:5173
```

If services aren't running: `docker compose up -d`

## Workflow Overview

The skill guides through 4 phases:

1. **Backend Implementation** - Models, migrations, permissions, endpoints, tests
2. **Type Generation** - Generate TypeScript types from OpenAPI schema
3. **Frontend Implementation** - API integration, components, forms, pages
4. **Integration Testing** - Verify end-to-end functionality

## Phase 1: Backend Implementation

Work in the `backend/` directory for all backend steps.

### Step 1.1: Gather Requirements

Ask the user:

1. **Feature name**: What resource/feature are you implementing? (e.g., "products", "orders", "blog posts")
2. **Database choice**: PostgreSQL (relational), MongoDB (flexible), or both?
3. **Fields**: What fields does the model need? (name, type, constraints)
4. **Relationships**: Does it relate to other models?
5. **Permissions**: What permissions are needed? (e.g., PRODUCTS_READ, PRODUCTS_WRITE, PRODUCTS_DELETE)
6. **Business logic**: Any special validation, calculations, or workflows?

### Step 1.2: Create Model

**For PostgreSQL (relational data)**:

Use the `fastapi-model` skill or create manually following this pattern:

```python
# backend/app/models/{feature}.py
from sqlalchemy import String, Text, Decimal, Integer, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base
from uuid import UUID
import uuid
from datetime import datetime

class Product(Base):
    __tablename__ = "products"

    # Primary key
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid.uuid4)

    # Fields
    name: Mapped[str] = mapped_column(String(200), index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    sku: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    price: Mapped[Decimal] = mapped_column(Decimal(10, 2))
    stock_quantity: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Foreign keys
    category_id: Mapped[UUID] = mapped_column(ForeignKey("categories.id"))

    # Relationships
    category: Mapped["Category"] = relationship(back_populates="products")

    # Timestamps
    created_at: Mapped[datetime]
    updated_at: Mapped[datetime]
```

**Key conventions**:
- Use `Mapped[]` type hints
- Include `id`, `created_at`, `updated_at` (inherited from Base)
- Add indexes on frequently queried fields
- Use proper types: `String`, `Text`, `Integer`, `Decimal`, `Boolean`, `DateTime`
- Add `unique=True` for unique constraints
- Use `nullable=True` for optional fields

**For MongoDB (flexible data)**:

```python
# backend/app/repositories/mongodb/{feature}_repository.py
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from datetime import datetime

class EventRepository:
    def __init__(self, db: AsyncIOMotorDatabase):
        self.collection = db["events"]

    async def create(self, event_data: dict):
        event_data["created_at"] = datetime.utcnow()
        result = await self.collection.insert_one(event_data)
        return str(result.inserted_id)
```

### Step 1.3: Create Migration (PostgreSQL only)

Use the `fastapi-migration` skill:

```bash
# In backend/
alembic revision --autogenerate -m "Add {feature} model"

# Review migration file in backend/app/alembic/versions/
# Check that auto-generated migration is correct

# Apply migration
alembic upgrade head

# Verify migration applied
alembic current
```

**Common migration checks**:
- ✅ All columns created with correct types
- ✅ Indexes added for queried fields
- ✅ Foreign keys reference correct tables
- ✅ Unique constraints applied
- ✅ Default values set

### Step 1.4: Add Permissions

Use the `fastapi-permission` skill or add manually:

```python
# backend/app/models/permission.py
class Permission(str, Enum):
    # ... existing permissions
    PRODUCTS_READ = "products:read"
    PRODUCTS_WRITE = "products:write"
    PRODUCTS_DELETE = "products:delete"
```

Create migration for permissions:

```bash
alembic revision -m "Add {feature} permissions"
```

Edit the migration to insert permissions:

```python
def upgrade():
    op.execute("""
        INSERT INTO permissions (name, description)
        VALUES
            ('products:read', 'View products'),
            ('products:write', 'Create and update products'),
            ('products:delete', 'Delete products')
    """)
```

Apply migration:

```bash
alembic upgrade head
```

### Step 1.5: Create Schemas

Create Pydantic schemas for validation:

```python
# backend/app/schemas/{feature}.py
from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime
from decimal import Decimal

class ProductBase(BaseModel):
    name: str = Field(..., max_length=200)
    description: str | None = None
    sku: str = Field(..., max_length=50)
    price: Decimal = Field(..., gt=0, decimal_places=2)
    stock_quantity: int = Field(default=0, ge=0)
    category_id: UUID

class ProductCreate(ProductBase):
    pass

class ProductUpdate(BaseModel):
    name: str | None = Field(None, max_length=200)
    description: str | None = None
    price: Decimal | None = Field(None, gt=0)
    stock_quantity: int | None = Field(None, ge=0)
    category_id: UUID | None = None

class ProductResponse(ProductBase):
    id: UUID
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
```

**Schema conventions**:
- `Base` - Shared fields
- `Create` - Fields required for creation
- `Update` - All fields optional (partial update)
- `Response` - Includes computed fields, timestamps, relationships

### Step 1.6: Create Repository

Create database access layer:

```python
# backend/app/repositories/{feature}_repository.py
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from app.models.{feature} import Product
from uuid import UUID

class ProductRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get(self, product_id: UUID) -> Product | None:
        result = await self.session.execute(
            select(Product).where(Product.id == product_id)
        )
        return result.scalar_one_or_none()

    async def get_paginated(
        self,
        offset: int = 0,
        limit: int = 10,
        filters: dict | None = None
    ) -> list[Product]:
        query = select(Product).where(Product.is_active == True)

        # Apply filters
        if filters:
            if "category_id" in filters:
                query = query.where(Product.category_id == filters["category_id"])
            if "search" in filters:
                search = f"%{filters['search']}%"
                query = query.where(Product.name.ilike(search))

        query = query.offset(offset).limit(limit)
        result = await self.session.execute(query)
        return result.scalars().all()

    async def create(self, product: Product) -> Product:
        self.session.add(product)
        await self.session.commit()
        await self.session.refresh(product)
        return product

    async def update(self, product_id: UUID, data: dict) -> Product | None:
        await self.session.execute(
            update(Product)
            .where(Product.id == product_id)
            .values(**data)
        )
        await self.session.commit()
        return await self.get(product_id)

    async def delete(self, product_id: UUID) -> bool:
        # Soft delete
        await self.session.execute(
            update(Product)
            .where(Product.id == product_id)
            .values(is_active=False)
        )
        await self.session.commit()
        return True
```

**Repository conventions**:
- Take `AsyncSession` in constructor
- Use `select()`, `update()`, `delete()` from SQLAlchemy
- Implement pagination with `offset` and `limit`
- Use soft delete (set `is_active=False`) unless hard delete required
- Return `None` if not found, not raise exception

### Step 1.7: Create Service

Create business logic layer:

```python
# backend/app/services/{feature}_service.py
from app.repositories.{feature}_repository import ProductRepository
from app.schemas.{feature} import ProductCreate, ProductUpdate
from app.models.{feature} import Product
from uuid import UUID

class ProductService:
    def __init__(self, repository: ProductRepository):
        self.repository = repository

    async def get_product(self, product_id: UUID) -> Product | None:
        return await self.repository.get(product_id)

    async def list_products(
        self,
        page: int = 1,
        size: int = 10,
        filters: dict | None = None
    ):
        offset = (page - 1) * size
        products = await self.repository.get_paginated(
            offset=offset,
            limit=size,
            filters=filters
        )
        total = await self.repository.count(filters=filters)

        return {
            "items": products,
            "total": total,
            "page": page,
            "size": size,
            "pages": (total + size - 1) // size
        }

    async def create_product(self, data: ProductCreate) -> Product:
        product = Product(**data.model_dump())
        return await self.repository.create(product)

    async def update_product(
        self,
        product_id: UUID,
        data: ProductUpdate
    ) -> Product | None:
        update_data = data.model_dump(exclude_unset=True)
        return await self.repository.update(product_id, update_data)

    async def delete_product(self, product_id: UUID) -> bool:
        return await self.repository.delete(product_id)
```

**Service conventions**:
- Take repository in constructor
- Implement business logic and validation
- Handle pagination calculations
- Convert schemas to models
- Return appropriate types (models, dicts, primitives)

### Step 1.8: Create API Endpoints

Create REST endpoints:

```python
# backend/app/api/v1/endpoints/{feature}.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.schemas.{feature} import ProductCreate, ProductUpdate, ProductResponse
from app.services.{feature}_service import ProductService
from app.repositories.{feature}_repository import ProductRepository
from app.common.dependencies import get_current_user, require_permissions
from app.models.permission import Permission
from app.models.user import User
from uuid import UUID

router = APIRouter(prefix="/products", tags=["products"])

def get_product_service(db: AsyncSession = Depends(get_db)) -> ProductService:
    repository = ProductRepository(db)
    return ProductService(repository)

@router.get("", response_model=dict)
@require_permissions(Permission.PRODUCTS_READ)
async def list_products(
    page: int = 1,
    size: int = 10,
    category_id: UUID | None = None,
    search: str | None = None,
    service: ProductService = Depends(get_product_service),
    current_user: User = Depends(get_current_user)
):
    """List products with pagination and filtering."""
    filters = {}
    if category_id:
        filters["category_id"] = category_id
    if search:
        filters["search"] = search

    return await service.list_products(page=page, size=size, filters=filters)

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
            detail=f"Product {product_id} not found"
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
    return await service.create_product(data)

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
            detail=f"Product {product_id} not found"
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
            detail=f"Product {product_id} not found"
        )
```

Register router in `backend/app/api/v1/api.py`:

```python
from app.api.v1.endpoints import {feature}

api_router.include_router({feature}.router)
```

**Endpoint conventions**:
- Use FastAPI dependency injection
- Apply `@require_permissions()` decorator
- Return appropriate status codes (200, 201, 204, 404)
- Raise `HTTPException` for errors
- Use proper response models

### Step 1.9: Write Tests

Use the `fastapi-test` skill or create manually:

```python
# backend/tests/test_{feature}.py
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_create_product(client: AsyncClient, admin_token: str):
    response = await client.post(
        "/api/v1/products",
        json={
            "name": "Test Product",
            "sku": "TEST-001",
            "price": 29.99,
            "category_id": "uuid-here"
        },
        headers={"Authorization": f"Bearer {admin_token}"}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Test Product"
    assert data["sku"] == "TEST-001"

@pytest.mark.asyncio
async def test_list_products(client: AsyncClient, admin_token: str):
    response = await client.get(
        "/api/v1/products?page=1&size=10",
        headers={"Authorization": f"Bearer {admin_token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert "page" in data

@pytest.mark.asyncio
async def test_get_product(client: AsyncClient, admin_token: str, product_id: str):
    response = await client.get(
        f"/api/v1/products/{product_id}",
        headers={"Authorization": f"Bearer {admin_token}"}
    )
    assert response.status_code == 200

@pytest.mark.asyncio
async def test_update_product(client: AsyncClient, admin_token: str, product_id: str):
    response = await client.put(
        f"/api/v1/products/{product_id}",
        json={"price": 39.99},
        headers={"Authorization": f"Bearer {admin_token}"}
    )
    assert response.status_code == 200
    assert response.json()["price"] == 39.99

@pytest.mark.asyncio
async def test_delete_product(client: AsyncClient, admin_token: str, product_id: str):
    response = await client.delete(
        f"/api/v1/products/{product_id}",
        headers={"Authorization": f"Bearer {admin_token}"}
    )
    assert response.status_code == 204

@pytest.mark.asyncio
async def test_permission_check(client: AsyncClient, user_token: str):
    """Test that non-admin users cannot delete products."""
    response = await client.delete(
        f"/api/v1/products/{product_id}",
        headers={"Authorization": f"Bearer {user_token}"}
    )
    assert response.status_code == 403
```

Run tests:

```bash
cd backend
pytest tests/test_{feature}.py -v
```

## Phase 2: Type Generation

Generate TypeScript types from backend OpenAPI schema.

### Step 2.1: Verify Backend OpenAPI

```bash
# Check OpenAPI schema is valid
curl http://localhost:8000/openapi.json | jq '.components.schemas' | grep -A 5 "ProductResponse"
```

### Step 2.2: Generate Types

```bash
cd frontend
npm run generate:types
```

This runs `openapi-typescript-codegen` which:
1. Fetches `http://localhost:8000/openapi.json`
2. Generates TypeScript types in `src/types/generated/api.ts`

### Step 2.3: Verify Generated Types

```bash
# Check types were generated
grep -A 10 "export interface ProductResponse" frontend/src/types/generated/api.ts

# Check Permission enum updated
grep "PRODUCTS_READ\|PRODUCTS_WRITE\|PRODUCTS_DELETE" frontend/src/types/generated/api.ts
```

## Phase 3: Frontend Implementation

Work in the `frontend/` directory for all frontend steps.

### Step 3.1: Create API Functions

```typescript
// frontend/src/features/{feature}/api/{feature}.ts
import { apiClient } from '@/lib/api-client';
import type {
  ProductResponse,
  ProductCreate,
  ProductUpdate,
  PaginatedResponse
} from '@/types/generated/api';

export const getProducts = async (params?: {
  page?: number;
  size?: number;
  category_id?: string;
  search?: string;
}): Promise<PaginatedResponse<ProductResponse>> => {
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

### Step 3.2: Create React Query Hooks

```typescript
// frontend/src/features/{feature}/hooks/use{Feature}.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import {
  getProducts,
  getProduct,
  createProduct,
  updateProduct,
  deleteProduct
} from '../api/{feature}';
import type { ProductCreate, ProductUpdate } from '@/types/generated/api';

export const useProducts = (filters?: {
  page?: number;
  size?: number;
  category_id?: string;
  search?: string;
}) => {
  return useQuery({
    queryKey: ['products', filters],
    queryFn: () => getProducts(filters),
    placeholderData: (prev) => prev, // Keep previous data while fetching
  });
};

export const useProduct = (id: string) => {
  return useQuery({
    queryKey: ['products', id],
    queryFn: () => getProduct(id),
    enabled: !!id,
  });
};

export const useCreateProduct = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: ProductCreate) => createProduct(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      toast.success('Product created successfully');
    },
  });
};

export const useUpdateProduct = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: ProductUpdate }) =>
      updateProduct(id, data),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['products', variables.id] });
      toast.success('Product updated successfully');
    },
  });
};

export const useDeleteProduct = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deleteProduct(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      toast.success('Product deleted successfully');
    },
  });
};
```

### Step 3.3: Create Zod Schemas

```typescript
// frontend/src/features/{feature}/schemas/{feature}.ts
import { z } from 'zod';

export const productSchema = z.object({
  name: z.string().min(1, 'Name is required').max(200),
  description: z.string().optional(),
  sku: z.string().min(1, 'SKU is required').max(50),
  price: z.number().positive('Price must be positive'),
  stock_quantity: z.number().int().min(0, 'Stock cannot be negative'),
  category_id: z.string().uuid('Invalid category'),
});

export type ProductFormData = z.infer<typeof productSchema>;
```

### Step 3.4: Create Components

**Product Card**:

```typescript
// frontend/src/features/{feature}/components/ProductCard.tsx
import { Card, CardContent, CardFooter } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Can } from '@/components/auth/Can';
import type { ProductResponse } from '@/types/generated/api';

interface ProductCardProps {
  product: ProductResponse;
  onEdit?: (id: string) => void;
  onDelete?: (id: string) => void;
}

export const ProductCard = ({ product, onEdit, onDelete }: ProductCardProps) => {
  const stockBadgeColor = product.stock_quantity === 0
    ? 'destructive'
    : product.stock_quantity < 10
    ? 'warning'
    : 'success';

  return (
    <Card>
      <CardContent className="pt-6">
        <h3 className="text-lg font-semibold">{product.name}</h3>
        <p className="text-sm text-muted-foreground">{product.description}</p>
        <div className="mt-4 flex items-center justify-between">
          <span className="text-2xl font-bold">${product.price}</span>
          <Badge variant={stockBadgeColor}>
            Stock: {product.stock_quantity}
          </Badge>
        </div>
      </CardContent>
      <CardFooter className="gap-2">
        <Can permission="PRODUCTS_WRITE">
          <Button onClick={() => onEdit?.(product.id)}>Edit</Button>
        </Can>
        <Can permission="PRODUCTS_DELETE">
          <Button
            variant="destructive"
            onClick={() => onDelete?.(product.id)}
          >
            Delete
          </Button>
        </Can>
      </CardFooter>
    </Card>
  );
};
```

**Product Form**:

```typescript
// frontend/src/features/{feature}/components/ProductForm.tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Form, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { productSchema, type ProductFormData } from '../schemas/{feature}';
import type { ProductResponse } from '@/types/generated/api';

interface ProductFormProps {
  product?: ProductResponse;
  onSubmit: (data: ProductFormData) => void;
  isLoading?: boolean;
}

export const ProductForm = ({ product, onSubmit, isLoading }: ProductFormProps) => {
  const form = useForm<ProductFormData>({
    resolver: zodResolver(productSchema),
    defaultValues: product || {
      name: '',
      description: '',
      sku: '',
      price: 0,
      stock_quantity: 0,
      category_id: '',
    },
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Name</FormLabel>
              <Input {...field} />
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="description"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Description</FormLabel>
              <Textarea {...field} />
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="sku"
          render={({ field }) => (
            <FormItem>
              <FormLabel>SKU</FormLabel>
              <Input {...field} />
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="price"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Price</FormLabel>
              <Input
                type="number"
                step="0.01"
                {...field}
                onChange={(e) => field.onChange(parseFloat(e.target.value))}
              />
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="stock_quantity"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Stock Quantity</FormLabel>
              <Input
                type="number"
                {...field}
                onChange={(e) => field.onChange(parseInt(e.target.value))}
              />
              <FormMessage />
            </FormItem>
          )}
        />

        <Button type="submit" disabled={isLoading}>
          {isLoading ? 'Saving...' : product ? 'Update' : 'Create'}
        </Button>
      </form>
    </Form>
  );
};
```

### Step 3.5: Create Pages

**List Page**:

```typescript
// frontend/src/features/{feature}/pages/ProductListPage.tsx
import { useState } from 'react';
import { useProducts, useDeleteProduct } from '../hooks/use{Feature}';
import { ProductCard } from '../components/ProductCard';
import { Button } from '@/components/ui/button';
import { Can } from '@/components/auth/Can';
import { Loader2 } from 'lucide-react';

export const ProductListPage = () => {
  const [page, setPage] = useState(1);
  const { data, isLoading } = useProducts({ page, size: 12 });
  const deleteProduct = useDeleteProduct();

  const handleDelete = (id: string) => {
    if (confirm('Are you sure you want to delete this product?')) {
      deleteProduct.mutate(id);
    }
  };

  if (isLoading) {
    return (
      <div className="flex justify-center p-8">
        <Loader2 className="h-8 w-8 animate-spin" />
      </div>
    );
  }

  return (
    <div className="container py-8">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-3xl font-bold">Products</h1>
        <Can permission="PRODUCTS_WRITE">
          <Button>Add Product</Button>
        </Can>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {data?.items.map((product) => (
          <ProductCard
            key={product.id}
            product={product}
            onDelete={handleDelete}
          />
        ))}
      </div>

      {/* Pagination */}
      <div className="mt-8 flex justify-center gap-2">
        <Button
          variant="outline"
          disabled={page === 1}
          onClick={() => setPage((p) => p - 1)}
        >
          Previous
        </Button>
        <span className="flex items-center px-4">
          Page {page} of {data?.pages}
        </span>
        <Button
          variant="outline"
          disabled={page === data?.pages}
          onClick={() => setPage((p) => p + 1)}
        >
          Next
        </Button>
      </div>
    </div>
  );
};
```

### Step 3.6: Add Routes

Add route to router configuration:

```typescript
// frontend/src/routes/products.tsx
import { createRoute } from '@tanstack/react-router';
import { rootRoute } from './root';
import { ProductListPage } from '@/features/products/pages/ProductListPage';

export const productsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/products',
  component: ProductListPage,
});
```

Register in router:

```typescript
// frontend/src/routes/index.tsx
import { productsRoute } from './products';

const routeTree = rootRoute.addChildren([
  // ... existing routes
  productsRoute,
]);
```

## Phase 4: Integration Testing

### Step 4.1: Test Backend API

```bash
# Login to get token
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin@example.com&password=admin123"

# Save token
TOKEN="your-access-token"

# Test create
curl -X POST http://localhost:8000/api/v1/products \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Product","sku":"TEST-001","price":29.99,"stock_quantity":100,"category_id":"uuid-here"}'

# Test list
curl http://localhost:8000/api/v1/products \
  -H "Authorization: Bearer $TOKEN"

# Test get
curl http://localhost:8000/api/v1/products/{id} \
  -H "Authorization: Bearer $TOKEN"
```

### Step 4.2: Test Frontend UI

1. Open http://localhost:5173/products
2. Verify products load
3. Test create (if permission)
4. Test edit (if permission)
5. Test delete (if permission)
6. Verify permission checks work

### Step 4.3: Integration Checklist

- [ ] Backend endpoints return correct data
- [ ] Frontend types match backend schemas
- [ ] Permissions enforced on backend
- [ ] Permissions hide/show UI on frontend
- [ ] Error messages display correctly
- [ ] Loading states work
- [ ] Pagination works
- [ ] Form validation works
- [ ] Success toasts appear
- [ ] Data refreshes after mutations

## Completion

After completing all phases:

1. **Run tests**: `cd backend && pytest tests/test_{feature}.py`
2. **Verify types**: Check `frontend/src/types/generated/api.ts` has correct types
3. **Manual test**: Test all CRUD operations in browser
4. **Check permissions**: Verify users without permissions cannot access
5. **Commit**: Create atomic commit with backend + frontend changes

```bash
git add backend/app/models/{feature}.py \
        backend/app/schemas/{feature}.py \
        backend/app/repositories/{feature}_repository.py \
        backend/app/services/{feature}_service.py \
        backend/app/api/v1/endpoints/{feature}.py \
        backend/tests/test_{feature}.py \
        backend/app/alembic/versions/*.py \
        frontend/src/features/{feature}/ \
        frontend/src/types/generated/api.ts

git commit -m "Add {feature} feature

- Backend: Models, migrations, CRUD endpoints, tests
- Permissions: {FEATURE}_READ, {FEATURE}_WRITE, {FEATURE}_DELETE
- Frontend: API integration, components, pages
- Type safety: Generated types from OpenAPI

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

## Troubleshooting

**Type generation fails**:
- Verify backend is running: `curl http://localhost:8000/docs`
- Check OpenAPI schema: `curl http://localhost:8000/openapi.json`
- Run manually: `cd frontend && npm run generate:types`

**401 errors**:
- Token expired - should auto-refresh via interceptor
- Check interceptor in `frontend/src/lib/api-client.ts`

**403 errors**:
- User missing permission
- Check permission assigned to role in backend
- Verify `@require_permissions()` decorator correct

**Types don't match**:
- Regenerate types: `cd frontend && npm run generate:types`
- Verify backend schemas in `backend/app/schemas/{feature}.py`

## Reference

- **Backend patterns**: `backend/docs/prompts/backend-patterns.md`
- **Frontend patterns**: `frontend/docs/prompts/frontend-patterns.md`
- **Integration patterns**: `docs/prompts/integration-patterns.md`
- **Full workflow**: `docs/FULLSTACK_WORKFLOW.md`
