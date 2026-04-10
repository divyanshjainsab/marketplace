export type NavItem = {
  href: string;
  label: string;
  tourId?: string;
};

export const NAV_ITEMS: NavItem[] = [
  { href: "/dashboard", label: "Dashboard", tourId: "nav-dashboard" },
  { href: "/listings", label: "Listings", tourId: "nav-listings" },
  { href: "/categories", label: "Categories", tourId: "nav-categories" },
  { href: "/products", label: "Products", tourId: "nav-products" },
  { href: "/site-editor", label: "Site Editor", tourId: "nav-site-editor" },
  { href: "/settings", label: "Settings" },
];

