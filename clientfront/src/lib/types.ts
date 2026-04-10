export type TenantInfo = {
  id: number;
  name: string;
  subdomain: string;
  organization_id: number;
};

export type SessionUser = {
  id: number;
  external_id: string;
  email: string | null;
  name: string | null;
  roles?: string[];
};

export type SessionResponse = {
  data: {
    user: SessionUser | null;
    marketplace: TenantInfo | null;
  };
};

export type Category = {
  id: number;
  name: string;
  code: string;
};

export type ProductType = {
  id: number;
  name: string;
  code: string;
};

export type Variant = {
  id: number;
  product_id: number;
  name: string;
  sku: string;
  options: Record<string, string>;
  image_url: string | null;
};

export type Product = {
  id: number;
  name: string;
  sku: string;
  metadata: Record<string, string>;
  image_url: string | null;
  category: Category;
  product_type: ProductType;
  variants?: Variant[];
};

export type Listing = {
  id: number;
  marketplace_id: number;
  price_cents: number | null;
  currency: string | null;
  status: string | null;
  product: Product;
  variant: Variant;
  updated_at: string;
};

export type ProductSuggestion = {
  product_id: number;
  name: string;
  sku: string;
  product_type: string | null;
  category: string | null;
  metadata: Record<string, string>;
};

export type PaginatedResponse<T> = {
  data: T[];
  meta: {
    page: number;
    per_page: number;
    total_count: number;
    total_pages: number;
  };
};
