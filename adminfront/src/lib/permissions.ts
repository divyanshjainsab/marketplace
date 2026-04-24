const ROUTE_PERMISSION_MAP: Array<{ prefix: string; permission: string }> = [
  { prefix: "/dashboard", permission: "view_dashboard" },
  { prefix: "/listings", permission: "view_listings" },
  { prefix: "/categories", permission: "view_categories" },
  { prefix: "/products", permission: "view_products" },
  { prefix: "/site-editor", permission: "manage_marketplace" },
  { prefix: "/settings", permission: "view_market_places" },
];

export function hasPermission(permissions: string[] | undefined, permission: string, isSuperAdmin = false) {
  if (isSuperAdmin) return true;

  return Array.isArray(permissions) && permissions.includes(permission);
}

export function requiredPermissionForPath(pathname: string) {
  const match = ROUTE_PERMISSION_MAP.find(({ prefix }) => pathname === prefix || pathname.startsWith(`${prefix}/`));
  return match?.permission ?? null;
}
