export type NavItem = {
  href: string;
  label: string;
  tourId?: string;
  permission?: string;
};

export const NAV_ITEMS: NavItem[] = [
  { href: "/dashboard", label: "Dashboard", tourId: "nav-dashboard", permission: "view_dashboard" },
  { href: "/listings", label: "Listings", tourId: "nav-listings", permission: "view_listings" },
  { href: "/categories", label: "Categories", tourId: "nav-categories", permission: "view_categories" },
  { href: "/products", label: "Products", tourId: "nav-products", permission: "view_products" },
  { href: "/site-editor", label: "Site Editor", tourId: "nav-site-editor", permission: "manage_marketplace" },
  { href: "/settings", label: "Settings", permission: "view_market_places" },
];
