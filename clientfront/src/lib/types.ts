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

export type Organization = {
  id: number;
  name: string;
  slug: string;
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

export type HomepageHeroBanner = {
  title?: string;
  subtitle?: string;
  image_url?: string;
  cta_text?: string;
  cta_href?: string;
};

export type PromotionalBlock = {
  title: string;
  body?: string;
  image_url?: string;
  href?: string;
};

export type HomepageConfig = {
  layout_order: Array<
    "hero_banner" | "featured_products" | "featured_listings" | "categories" | "promotional_blocks"
  >;
  hero_banner?: HomepageHeroBanner;
  featured_products?: number[];
  featured_listings?: number[];
  categories?: string[];
  promotional_blocks?: PromotionalBlock[];
};

export type HomepageResponse = {
  data: {
    organization: Organization;
    marketplace: TenantInfo;
    homepage_config: HomepageConfig;
    resolved: {
      featured_products: Product[];
      featured_listings: Listing[];
      categories: Category[];
    };
  };
};
