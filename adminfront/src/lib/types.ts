export type SessionUser = {
  id: number;
  external_id: string;
  email: string | null;
  name: string | null;
  roles?: string[];
};

export type Organization = {
  id: number;
  name: string;
  slug: string;
};

export type Marketplace = {
  id: number;
  name: string;
  subdomain: string;
  custom_domain?: string | null;
  organization_id: number;
};

export type SessionResponse = {
  data: {
    authenticated: boolean;
    admin_authorized: boolean;
    tenant_resolved: boolean;
    user: SessionUser | null;
    marketplace: Marketplace | null;
    organization?: Organization | null;
  };
};

export type AdminContextResponse = {
  data: {
    organization: Organization;
    marketplaces: Marketplace[];
  };
};

export type PaginationMeta = {
  page: number;
  per_page: number;
  total_count: number;
  total_pages: number;
};

export type PaginatedResponse<T> = {
  data: T[];
  meta: PaginationMeta;
};

export type Category = {
  id: number;
  name: string;
  code: string;
  product_count?: number;
};

export type ProductType = {
  id: number;
  name: string;
  code: string;
  product_count?: number;
};

export type Variant = {
  id: number;
  sku: string;
  name: string;
  options?: Record<string, unknown>;
};

export type Product = {
  id: number;
  name: string;
  sku: string;
  metadata?: Record<string, unknown>;
  image_url?: string | null;
  category: Category;
  product_type: ProductType;
  listing_count?: number;
};

export type ProductSuggestion = {
  product_id: number;
  name: string;
  sku: string;
  product_type: string | null;
  category: string | null;
  metadata: Record<string, unknown>;
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

export type DashboardResponse = {
  data: {
    organization: Organization;
    marketplace: Marketplace;
    totals: {
      products: number;
      listings: number;
    };
    category_distribution: Array<{
      category: Category;
      product_count: number;
    }>;
    product_type_distribution: Array<{
      product_type: ProductType;
      product_count: number;
    }>;
    listing_status_distribution: Array<{
      status: string;
      listing_count: number;
    }>;
    recent_activity: Array<{
      type: "listing";
      id: number;
      label: string;
      status: string | null;
      updated_at: string;
    }>;
    marketplace_status: {
      id: number;
      name: string;
      subdomain: string;
      custom_domain: string | null;
    };
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

export type SiteEditorResponse = {
  data: {
    organization: Organization;
    homepage_config: HomepageConfig;
  };
};
