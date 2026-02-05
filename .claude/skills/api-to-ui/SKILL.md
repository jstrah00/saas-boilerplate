---
name: api-to-ui
description: Create complete frontend UI integration for an existing backend API endpoint. Use when backend is already implemented and you need to build the UI layer. Generates API client functions, React Query hooks, components, forms, and pages connected to existing endpoints. Ensures type safety by using generated types from OpenAPI schema.
---

# API to UI Integration

Create complete frontend UI integration for existing backend API endpoints. This skill assumes the backend is already implemented and guides you through building the UI layer with proper type safety and integration.

## When to Use This Skill

- [X] Backend endpoint already exists and is working
- [X] Need to build frontend UI for existing API
- [X] Want to add new pages/components for existing backend features
- [X] Backend types need to be exposed to frontend
- [X] Connecting frontend to newly deployed backend services

**Don't use when**: Backend doesn't exist yet → Use `/backend-first` skill instead

## Prerequisites Check

Before starting, verify:

```bash
# Backend is running
curl http://localhost:8000/docs

# Check endpoint exists in Swagger UI
open http://localhost:8000/docs

# Frontend is running
curl http://localhost:5173
```

If services aren't running: `docker compose up -d`

## Workflow Overview

The skill guides through 7 steps:

1. **Verify Backend** - Confirm endpoint exists and review response models
2. **Generate Types** - Generate TypeScript types from OpenAPI
3. **Create API Integration** - API functions using generated types
4. **Create React Query Hooks** - useQuery and useMutation hooks
5. **Create UI Components** - Cards, forms, lists with shadcn/ui
6. **Create Pages & Routes** - Pages with routing and permissions
7. **Add Translations** - i18n keys for all UI text

## Step 1: Verify Backend Endpoint

### Step 1.1: Gather Information

Ask the user:

1. **Backend endpoint path**: What's the API path? (e.g., `/api/v1/products`)
2. **Feature name**: What's the feature called? (e.g., "products", "orders")
3. **Endpoint methods**: What HTTP methods? (GET list, GET detail, POST, PUT, DELETE)
4. **Permissions**: What permissions are required? (e.g., PRODUCTS_READ, PRODUCTS_WRITE)
5. **UI components needed**: List, detail, form, or all three?

### Step 1.2: Verify Endpoint Exists

Check the backend has the endpoint:

```bash
# Method 1: Check in Swagger UI
open http://localhost:8000/docs
# Look for the endpoint in the API docs

# Method 2: Check source code
ls backend/app/api/v1/endpoints/{feature}.py

# Method 3: Test endpoint directly
curl http://localhost:8000/api/v1/{feature} \
 -H "Authorization: Bearer $TOKEN"
```

**If endpoint doesn't exist**: Stop and use `/backend-first` skill first.

### Step 1.3: Review Response Models

Check OpenAPI schema for response types:

```bash
# Get OpenAPI schema
curl http://localhost:8000/openapi.json | jq '.components.schemas' | grep -A 10 "{FeatureName}"

# Example output:
# "ProductResponse": {
# "properties": {
# "id": {"type": "string", "format": "uuid"},
# "name": {"type": "string"},
# "price": {"type": "number"}
# }
# }
```

Note the schema names (e.g., `ProductResponse`, `ProductCreate`, `ProductUpdate`) - you'll use these in frontend code.

## Step 2: Generate Types

Generate TypeScript types from backend OpenAPI schema.

### Step 2.1: Run Type Generation

```bash
cd frontend
npm run generate:types
```

This command:
1. Fetches `http://localhost:8000/openapi.json`
2. Generates TypeScript types in `src/types/generated/api.ts`
3. Creates interfaces for all Pydantic schemas
4. Generates Permission enum

### Step 2.2: Verify Types Generated

```bash
# Check feature types exist
grep -A 10 "export interface {Feature}Response" frontend/src/types/generated/api.ts

# Example: For products
grep -A 10 "export interface ProductResponse" frontend/src/types/generated/api.ts

# Check permissions
grep "{FEATURE}_READ\|{FEATURE}_WRITE" frontend/src/types/generated/api.ts
```

**If types don't exist**: Backend schemas might not be exposed. Check backend endpoint has proper `response_model` parameter.

### Step 2.3: Identify Required Types

Based on the endpoint methods, identify which types you'll need:

**For GET endpoints**:
- `{Feature}Response` - Single item response
- `PaginatedResponse<{Feature}Response>` - List response (if paginated)

**For POST endpoints**:
- `{Feature}Create` - Creation request body

**For PUT/PATCH endpoints**:
- `{Feature}Update` - Update request body

**For DELETE endpoints**:
- No special types needed (just ID)

## Step 3: Create API Integration

Create API client functions in the features directory.

### Step 3.1: Create API File

Create `frontend/src/features/{feature}/api/{feature}.ts`:

```typescript
import { apiClient } from '@/lib/api-client';
import type {
 ProductResponse,
 ProductCreate,
 ProductUpdate,
 PaginatedResponse
} from '@/types/generated/api';

// GET list - with pagination and filters
export const getProducts = async (params?: {
 page?: number;
 size?: number;
 search?: string;
 // Add other filter params from backend
}): Promise<PaginatedResponse<ProductResponse>> => {
 const { data } = await apiClient.get('/products', { params });
 return data;
};

// GET single item
export const getProduct = async (id: string): Promise<ProductResponse> => {
 const { data } = await apiClient.get(`/products/${id}`);
 return data;
};

// POST - create
export const createProduct = async (
 product: ProductCreate
): Promise<ProductResponse> => {
 const { data } = await apiClient.post('/products', product);
 return data;
};

// PUT - update
export const updateProduct = async (
 id: string,
 product: ProductUpdate
): Promise<ProductResponse> => {
 const { data } = await apiClient.put(`/products/${id}`, product);
 return data;
};

// DELETE
export const deleteProduct = async (id: string): Promise<void> => {
 await apiClient.delete(`/products/${id}`);
};
```

**Key points**:
- Use `apiClient` from `@/lib/api-client` (has auth interceptors)
- Import types from `@/types/generated/api`
- Match function parameters to backend query params
- Return types match backend response models

### Step 3.2: Handle Special Cases

**File Upload**:
```typescript
export const uploadProductImage = async (
 productId: string,
 file: File
): Promise<{ image_url: string }> => {
 const formData = new FormData();
 formData.append('file', file);

 const { data } = await apiClient.post(
 `/products/${productId}/image`,
 formData,
 {
 headers: { 'Content-Type': 'multipart/form-data' }
 }
 );

 return data;
};
```

**Non-Paginated List**:
```typescript
export const getProducts = async (): Promise<ProductResponse[]> => {
 const { data } = await apiClient.get('/products');
 return data; // Returns array directly, not paginated response
};
```

**Custom Endpoints**:
```typescript
// Example: POST /products/{id}/publish
export const publishProduct = async (id: string): Promise<ProductResponse> => {
 const { data } = await apiClient.post(`/products/${id}/publish`);
 return data;
};
```

## Step 4: Create React Query Hooks

Create React Query hooks for data fetching and mutations.

### Step 4.1: Create Hooks File

Create `frontend/src/features/{feature}/hooks/use{Feature}.ts`:

```typescript
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

// Query: List with filters
export const useProducts = (filters?: {
 page?: number;
 size?: number;
 search?: string;
}) => {
 return useQuery({
 queryKey: ['products', filters],
 queryFn: () => getProducts(filters),
 placeholderData: (prev) => prev, // Keep previous data while fetching new page
 });
};

// Query: Single item
export const useProduct = (id: string | undefined) => {
 return useQuery({
 queryKey: ['products', id],
 queryFn: () => getProduct(id!),
 enabled: !!id, // Only fetch when id is provided
 });
};

// Mutation: Create
export const useCreateProduct = () => {
 const queryClient = useQueryClient();

 return useMutation({
 mutationFn: (data: ProductCreate) => createProduct(data),
 onSuccess: () => {
 // Invalidate list query to refetch
 queryClient.invalidateQueries({ queryKey: ['products'] });
 toast.success('Product created successfully');
 },
 onError: (error: any) => {
 // Error toast shown by interceptor, but can add custom logic
 console.error('Failed to create product:', error);
 },
 });
};

// Mutation: Update
export const useUpdateProduct = () => {
 const queryClient = useQueryClient();

 return useMutation({
 mutationFn: ({ id, data }: { id: string; data: ProductUpdate }) =>
 updateProduct(id, data),
 onSuccess: (_, variables) => {
 // Invalidate both list and detail queries
 queryClient.invalidateQueries({ queryKey: ['products'] });
 queryClient.invalidateQueries({ queryKey: ['products', variables.id] });
 toast.success('Product updated successfully');
 },
 });
};

// Mutation: Delete
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

**Key patterns**:
- Use `queryKey` as array (first element = feature name)
- Include filters in `queryKey` for proper caching
- Set `enabled: !!id` for conditional queries
- Use `placeholderData` to keep previous data during pagination
- Invalidate queries after mutations
- Show success toasts (errors handled by interceptor)

### Step 4.2: Handle Advanced Patterns

**Optimistic Updates**:
```typescript
export const useUpdateProduct = () => {
 const queryClient = useQueryClient();

 return useMutation({
 mutationFn: ({ id, data }: { id: string; data: ProductUpdate }) =>
 updateProduct(id, data),
 onMutate: async ({ id, data }) => {
 // Cancel outgoing refetches
 await queryClient.cancelQueries({ queryKey: ['products', id] });

 // Snapshot previous value
 const previous = queryClient.getQueryData(['products', id]);

 // Optimistically update
 queryClient.setQueryData(['products', id], (old: any) => ({
 ...old,
 ...data
 }));

 return { previous };
 },
 onError: (err, variables, context) => {
 // Rollback on error
 queryClient.setQueryData(['products', variables.id], context?.previous);
 },
 onSettled: (_, __, variables) => {
 // Refetch regardless of success/error
 queryClient.invalidateQueries({ queryKey: ['products', variables.id] });
 },
 });
};
```

**Infinite Scroll**:
```typescript
export const useInfiniteProducts = (filters?: { search?: string }) => {
 return useInfiniteQuery({
 queryKey: ['products', 'infinite', filters],
 queryFn: ({ pageParam = 1 }) =>
 getProducts({ ...filters, page: pageParam, size: 20 }),
 getNextPageParam: (lastPage) =>
 lastPage.page < lastPage.pages ? lastPage.page + 1 : undefined,
 initialPageParam: 1,
 });
};
```

## Step 5: Create UI Components

Create UI components using shadcn/ui.

### Step 5.1: Create Card Component

Display item in card format:

```typescript
// frontend/src/features/{feature}/components/ProductCard.tsx
import { Card, CardContent, CardFooter, CardHeader } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Can } from '@/components/auth/Can';
import { Edit, Trash2 } from 'lucide-react';
import type { ProductResponse } from '@/types/generated/api';

interface ProductCardProps {
 product: ProductResponse;
 onEdit?: (id: string) => void;
 onDelete?: (id: string) => void;
}

export const ProductCard = ({ product, onEdit, onDelete }: ProductCardProps) => {
 return (
 <Card>
 <CardHeader>
 <div className="flex items-start justify-between">
 <h3 className="text-lg font-semibold">{product.name}</h3>
 {product.is_active && (
 <Badge variant="success">Active</Badge>
 )}
 </div>
 </CardHeader>

 <CardContent>
 <p className="text-sm text-muted-foreground line-clamp-2">
 {product.description}
 </p>
 <div className="mt-4">
 <span className="text-2xl font-bold">${product.price}</span>
 </div>
 </CardContent>

 <CardFooter className="gap-2">
 <Can permission="PRODUCTS_WRITE">
 <Button
 variant="outline"
 size="sm"
 onClick={() => onEdit?.(product.id)}
 >
 <Edit className="h-4 w-4 mr-2" />
 Edit
 </Button>
 </Can>

 <Can permission="PRODUCTS_DELETE">
 <Button
 variant="destructive"
 size="sm"
 onClick={() => onDelete?.(product.id)}
 >
 <Trash2 className="h-4 w-4 mr-2" />
 Delete
 </Button>
 </Can>
 </CardFooter>
 </Card>
 );
};
```

**Key patterns**:
- Use shadcn/ui components (Card, Button, Badge)
- Add permission checks with `<Can>` component
- Use lucide-react icons
- Add optional callbacks for actions
- Use Tailwind classes for styling

### Step 5.2: Create Form Component

Create/edit form with validation:

```typescript
// frontend/src/features/{feature}/components/ProductForm.tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import {
 Form,
 FormField,
 FormItem,
 FormLabel,
 FormControl,
 FormMessage,
 FormDescription
} from '@/components/ui/form';
import type { ProductResponse } from '@/types/generated/api';

// Define Zod schema matching backend validation
const productSchema = z.object({
 name: z.string().min(1, 'Name is required').max(200, 'Name too long'),
 description: z.string().optional(),
 price: z.number().positive('Price must be positive').multipleOf(0.01),
 stock_quantity: z.number().int().min(0, 'Stock cannot be negative'),
});

type ProductFormData = z.infer<typeof productSchema>;

interface ProductFormProps {
 product?: ProductResponse; // For edit mode
 onSubmit: (data: ProductFormData) => void;
 isLoading?: boolean;
}

export const ProductForm = ({ product, onSubmit, isLoading }: ProductFormProps) => {
 const form = useForm<ProductFormData>({
 resolver: zodResolver(productSchema),
 defaultValues: product || {
 name: '',
 description: '',
 price: 0,
 stock_quantity: 0,
 },
 });

 return (
 <Form {...form}>
 <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
 <FormField
 control={form.control}
 name="name"
 render={({ field }) => (
 <FormItem>
 <FormLabel>Product Name</FormLabel>
 <FormControl>
 <Input placeholder="Enter product name" {...field} />
 </FormControl>
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
 <FormControl>
 <Textarea
 placeholder="Enter product description"
 {...field}
 />
 </FormControl>
 <FormDescription>
 Optional description of the product
 </FormDescription>
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
 <FormControl>
 <Input
 type="number"
 step="0.01"
 placeholder="0.00"
 {...field}
 onChange={(e) => field.onChange(parseFloat(e.target.value))}
 />
 </FormControl>
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
 <FormControl>
 <Input
 type="number"
 placeholder="0"
 {...field}
 onChange={(e) => field.onChange(parseInt(e.target.value))}
 />
 </FormControl>
 <FormMessage />
 </FormItem>
 )}
 />

 <Button type="submit" disabled={isLoading} className="w-full">
 {isLoading ? 'Saving...' : product ? 'Update Product' : 'Create Product'}
 </Button>
 </form>
 </Form>
 );
};
```

**Key patterns**:
- Use Zod schema matching backend Pydantic validation
- Use react-hook-form with zodResolver
- Convert string inputs to numbers for numeric fields
- Show loading state during submission
- Support both create and edit modes

### Step 5.3: Create List Component

Display items in a list or table:

```typescript
// frontend/src/features/{feature}/components/ProductList.tsx
import { ProductCard } from './ProductCard';
import { Loader2 } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import type { ProductResponse } from '@/types/generated/api';

interface ProductListProps {
 products: ProductResponse[] | undefined;
 isLoading: boolean;
 isError: boolean;
 error?: Error;
 onEdit?: (id: string) => void;
 onDelete?: (id: string) => void;
}

export const ProductList = ({
 products,
 isLoading,
 isError,
 error,
 onEdit,
 onDelete
}: ProductListProps) => {
 if (isLoading) {
 return (
 <div className="flex justify-center items-center p-12">
 <Loader2 className="h-8 w-8 animate-spin text-primary" />
 </div>
 );
 }

 if (isError) {
 return (
 <Alert variant="destructive">
 <AlertDescription>
 {error?.message || 'Failed to load products'}
 </AlertDescription>
 </Alert>
 );
 }

 if (!products || products.length === 0) {
 return (
 <div className="text-center p-12">
 <p className="text-muted-foreground">No products found</p>
 </div>
 );
 }

 return (
 <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
 {products.map((product) => (
 <ProductCard
 key={product.id}
 product={product}
 onEdit={onEdit}
 onDelete={onDelete}
 />
 ))}
 </div>
 );
};
```

**Key patterns**:
- Handle loading, error, and empty states
- Use grid layout (responsive)
- Pass callbacks to child components
- Show user-friendly messages

## Step 6: Create Pages & Routes

Create pages and add routing.

### Step 6.1: Create List Page

```typescript
// frontend/src/features/{feature}/pages/ProductListPage.tsx
import { useState } from 'react';
import { useProducts, useDeleteProduct } from '../hooks/useProducts';
import { ProductList } from '../components/ProductList';
import { ProductForm } from '../components/ProductForm';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Can } from '@/components/auth/Can';
import { Plus, Search } from 'lucide-react';

export const ProductListPage = () => {
 const [page, setPage] = useState(1);
 const [search, setSearch] = useState('');
 const [isCreateOpen, setIsCreateOpen] = useState(false);

 const { data, isLoading, isError, error } = useProducts({ page, search, size: 12 });
 const deleteProduct = useDeleteProduct();
 const createProduct = useCreateProduct();

 const handleDelete = (id: string) => {
 if (confirm('Are you sure you want to delete this product?')) {
 deleteProduct.mutate(id);
 }
 };

 const handleCreate = (data: ProductFormData) => {
 createProduct.mutate(data, {
 onSuccess: () => {
 setIsCreateOpen(false);
 }
 });
 };

 return (
 <div className="container py-8">
 {/* Header */}
 <div className="flex items-center justify-between mb-6">
 <div>
 <h1 className="text-3xl font-bold">Products</h1>
 <p className="text-muted-foreground mt-1">
 Manage your product catalog
 </p>
 </div>

 <Can permission="PRODUCTS_WRITE">
 <Dialog open={isCreateOpen} onOpenChange={setIsCreateOpen}>
 <DialogTrigger asChild>
 <Button>
 <Plus className="h-4 w-4 mr-2" />
 Add Product
 </Button>
 </DialogTrigger>
 <DialogContent>
 <DialogHeader>
 <DialogTitle>Create Product</DialogTitle>
 </DialogHeader>
 <ProductForm
 onSubmit={handleCreate}
 isLoading={createProduct.isPending}
 />
 </DialogContent>
 </Dialog>
 </Can>
 </div>

 {/* Search */}
 <div className="mb-6">
 <div className="relative max-w-sm">
 <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
 <Input
 placeholder="Search products..."
 value={search}
 onChange={(e) => setSearch(e.target.value)}
 className="pl-10"
 />
 </div>
 </div>

 {/* List */}
 <ProductList
 products={data?.items}
 isLoading={isLoading}
 isError={isError}
 error={error}
 onDelete={handleDelete}
 />

 {/* Pagination */}
 {data && data.pages > 1 && (
 <div className="mt-8 flex justify-center gap-2">
 <Button
 variant="outline"
 disabled={page === 1}
 onClick={() => setPage((p) => p - 1)}
 >
 Previous
 </Button>
 <span className="flex items-center px-4">
 Page {page} of {data.pages}
 </span>
 <Button
 variant="outline"
 disabled={page >= data.pages}
 onClick={() => setPage((p) => p + 1)}
 >
 Next
 </Button>
 </div>
 )}
 </div>
 );
};
```

**Key patterns**:
- Header with title and action button
- Search input with debouncing (optional)
- Dialog for create form
- Pagination controls
- Permission checks for actions

### Step 6.2: Create Detail Page (Optional)

```typescript
// frontend/src/features/{feature}/pages/ProductDetailPage.tsx
import { useParams, useNavigate } from '@tanstack/react-router';
import { useProduct, useUpdateProduct, useDeleteProduct } from '../hooks/useProducts';
import { ProductForm } from '../components/ProductForm';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Can } from '@/components/auth/Can';
import { Loader2, ArrowLeft, Edit, Trash2 } from 'lucide-react';
import { useState } from 'react';

export const ProductDetailPage = () => {
 const { id } = useParams({ from: '/products/$id' });
 const navigate = useNavigate();
 const [isEditOpen, setIsEditOpen] = useState(false);

 const { data: product, isLoading } = useProduct(id);
 const updateProduct = useUpdateProduct();
 const deleteProduct = useDeleteProduct();

 const handleUpdate = (data: ProductFormData) => {
 updateProduct.mutate(
 { id, data },
 {
 onSuccess: () => {
 setIsEditOpen(false);
 }
 }
 );
 };

 const handleDelete = () => {
 if (confirm('Are you sure you want to delete this product?')) {
 deleteProduct.mutate(id, {
 onSuccess: () => {
 navigate({ to: '/products' });
 }
 });
 }
 };

 if (isLoading) {
 return (
 <div className="flex justify-center items-center min-h-screen">
 <Loader2 className="h-8 w-8 animate-spin" />
 </div>
 );
 }

 if (!product) {
 return <div>Product not found</div>;
 }

 return (
 <div className="container py-8">
 {/* Header */}
 <div className="mb-6">
 <Button variant="ghost" onClick={() => navigate({ to: '/products' })}>
 <ArrowLeft className="h-4 w-4 mr-2" />
 Back to Products
 </Button>
 </div>

 {/* Content */}
 <Card>
 <CardHeader>
 <div className="flex items-start justify-between">
 <div>
 <h1 className="text-3xl font-bold">{product.name}</h1>
 <p className="text-muted-foreground mt-1">{product.description}</p>
 </div>

 <div className="flex gap-2">
 <Can permission="PRODUCTS_WRITE">
 <Dialog open={isEditOpen} onOpenChange={setIsEditOpen}>
 <Button variant="outline" onClick={() => setIsEditOpen(true)}>
 <Edit className="h-4 w-4 mr-2" />
 Edit
 </Button>
 <DialogContent>
 <DialogHeader>
 <DialogTitle>Edit Product</DialogTitle>
 </DialogHeader>
 <ProductForm
 product={product}
 onSubmit={handleUpdate}
 isLoading={updateProduct.isPending}
 />
 </DialogContent>
 </Dialog>
 </Can>

 <Can permission="PRODUCTS_DELETE">
 <Button variant="destructive" onClick={handleDelete}>
 <Trash2 className="h-4 w-4 mr-2" />
 Delete
 </Button>
 </Can>
 </div>
 </div>
 </CardHeader>

 <CardContent>
 <dl className="grid grid-cols-2 gap-4">
 <div>
 <dt className="text-sm font-medium text-muted-foreground">Price</dt>
 <dd className="text-2xl font-bold">${product.price}</dd>
 </div>
 <div>
 <dt className="text-sm font-medium text-muted-foreground">Stock</dt>
 <dd className="text-2xl font-bold">{product.stock_quantity}</dd>
 </div>
 <div>
 <dt className="text-sm font-medium text-muted-foreground">Created</dt>
 <dd>{new Date(product.created_at).toLocaleDateString()}</dd>
 </div>
 <div>
 <dt className="text-sm font-medium text-muted-foreground">Updated</dt>
 <dd>{new Date(product.updated_at).toLocaleDateString()}</dd>
 </div>
 </dl>
 </CardContent>
 </Card>
 </div>
 );
};
```

### Step 6.3: Add Routes

Add routes to router configuration:

```typescript
// frontend/src/routes/products.tsx
import { createRoute } from '@tanstack/react-router';
import { rootRoute } from './root';
import { ProductListPage } from '@/features/products/pages/ProductListPage';
import { ProductDetailPage } from '@/features/products/pages/ProductDetailPage';

export const productsIndexRoute = createRoute({
 getParentRoute: () => rootRoute,
 path: '/products',
 component: ProductListPage,
});

export const productDetailRoute = createRoute({
 getParentRoute: () => rootRoute,
 path: '/products/$id',
 component: ProductDetailPage,
});
```

Register routes:

```typescript
// frontend/src/routes/index.tsx
import { productsIndexRoute, productDetailRoute } from './products';

const routeTree = rootRoute.addChildren([
 // ... existing routes
 productsIndexRoute,
 productDetailRoute,
]);
```

## Step 7: Add Translations (i18n)

Add translation keys for all UI text.

### Step 7.1: Add English Translations

Edit `frontend/src/locales/en/translation.json`:

```json
{
 "products": {
 "title": "Products",
 "description": "Manage your product catalog",
 "add": "Add Product",
 "edit": "Edit Product",
 "delete": "Delete Product",
 "search": "Search products...",
 "empty": "No products found",
 "deleteConfirm": "Are you sure you want to delete this product?",
 "fields": {
 "name": "Product Name",
 "description": "Description",
 "price": "Price",
 "stock": "Stock Quantity"
 },
 "messages": {
 "createSuccess": "Product created successfully",
 "updateSuccess": "Product updated successfully",
 "deleteSuccess": "Product deleted successfully",
 "loadError": "Failed to load products"
 }
 }
}
```

### Step 7.2: Add Spanish Translations

Edit `frontend/src/locales/es/translation.json`:

```json
{
 "products": {
 "title": "Productos",
 "description": "Gestiona tu catálogo de productos",
 "add": "Agregar Producto",
 "edit": "Editar Producto",
 "delete": "Eliminar Producto",
 "search": "Buscar productos...",
 "empty": "No se encontraron productos",
 "deleteConfirm": "¿Estás seguro de que quieres eliminar este producto?",
 "fields": {
 "name": "Nombre del Producto",
 "description": "Descripción",
 "price": "Precio",
 "stock": "Cantidad en Stock"
 },
 "messages": {
 "createSuccess": "Producto creado exitosamente",
 "updateSuccess": "Producto actualizado exitosamente",
 "deleteSuccess": "Producto eliminado exitosamente",
 "loadError": "Error al cargar productos"
 }
 }
}
```

### Step 7.3: Use Translations in Components

Update components to use translations:

```typescript
import { useTranslation } from 'react-i18next';

export const ProductListPage = () => {
 const { t } = useTranslation();

 return (
 <div className="container py-8">
 <h1 className="text-3xl font-bold">{t('products.title')}</h1>
 <p className="text-muted-foreground">{t('products.description')}</p>

 <Button>
 <Plus className="h-4 w-4 mr-2" />
 {t('products.add')}
 </Button>

 <Input placeholder={t('products.search')} />

 {/* ... */}
 </div>
 );
};
```

Update toast messages:

```typescript
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
```

## Completion Checklist

After completing all steps:

- [ ] Backend endpoint verified and working
- [ ] Types generated from OpenAPI schema
- [ ] API functions created using generated types
- [ ] React Query hooks implemented (queries + mutations)
- [ ] UI components created (Card, Form, List)
- [ ] Pages created (List, Detail if needed)
- [ ] Routes registered in router
- [ ] Permission checks added with `<Can>` component
- [ ] i18n translations added (English + Spanish)
- [ ] Manual testing in browser completed
- [ ] Loading states work correctly
- [ ] Error states display properly
- [ ] Success toasts appear
- [ ] Data refreshes after mutations

## Testing

### Test List Page

1. Navigate to http://localhost:5173/products
2. Verify products load
3. Test search/filter functionality
4. Test pagination (if applicable)
5. Verify "Add" button shows for users with PRODUCTS_WRITE permission
6. Test create product form
7. Test edit product (if in list)
8. Test delete product with confirmation

### Test Detail Page (if created)

1. Click on a product to view detail
2. Verify all data displays correctly
3. Test edit functionality
4. Test delete with redirect to list

### Test Permissions

1. Log in as user without permissions
2. Verify action buttons are hidden
3. Verify API calls still fail if attempted (backend enforces)

### Test Error Handling

1. Stop backend: `docker compose stop backend`
2. Verify error messages display
3. Start backend and verify recovery

## Troubleshooting

**Types not found**:
- Run `npm run generate:types` in frontend/
- Check backend has `response_model` on endpoints
- Verify backend is running

**API calls fail with 401**:
- Token expired (should auto-refresh)
- Check `apiClient` has interceptor
- Verify token in localStorage

**API calls fail with 403**:
- User lacks required permission
- Check permission assigned to user's role
- Verify backend `@require_permissions()` decorator

**Components not styled correctly**:
- Verify shadcn/ui components installed
- Check Tailwind CSS configured
- Verify className props used

**Translations not working**:
- Check i18n initialized in app
- Verify translation keys match
- Check `useTranslation()` imported

## Reference

- **Frontend patterns**: `frontend/docs/prompts/frontend-patterns.md`
- **Integration patterns**: `docs/prompts/integration-patterns.md`
- **Backend API**: http://localhost:8000/docs (Swagger UI)
- **Generated types**: `frontend/src/types/generated/api.ts`
