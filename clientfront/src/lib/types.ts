export type TenantInfo = {
  id: number;
  name: string;
  custom_domain: string;
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
  parent_id?: number | null;
};

export type ProductType = {
  id: number;
  name: string;
  code: string;
};

export type MediaAsset = {
  public_id: string;
  optimized_url: string;
  version: number;
  width: number;
  height: number;
  urls: {
    thumbnail?: string;
    medium?: string;
    full: string;
  };
};

export type Variant = {
  id: number;
  product_id: number;
  name: string;
  sku: string;
  options: Record<string, string>;
  image_url: string | null;
  image?: MediaAsset | null;
};

export type Product = {
  id: number;
  name: string;
  sku: string;
  metadata: Record<string, string>;
  image_url: string | null;
  image?: MediaAsset | null;
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
  inventory_count: number;
  image_url?: string | null;
  image?: MediaAsset | null;
  image_source?: string | null;
  product: Product;
  variant: Variant;
  updated_at: string;
};

export type CartItem = {
  id: number;
  variant_id: number;
  quantity: number;
  unit_price_cents: number | null;
  currency: string | null;
  line_total_cents: number | null;
  inventory_count: number | null;
  available: boolean;
  listing: Listing | null;
};

export type Cart = {
  id: number;
  marketplace_id: number;
  user_id: number | null;
  session_id: string;
  item_count: number;
  subtotal_cents: number;
  items: CartItem[];
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
  image?: MediaAsset | null;
  cta_text?: string;
  cta_href?: string;
};

export type PromotionalBlock = {
  title: string;
  body?: string;
  image?: MediaAsset | null;
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
