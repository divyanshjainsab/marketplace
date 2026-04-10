export type TourStep = {
  id: string;
  route: string;
  selector: string;
  title: string;
  body: string;
};

export const TOUR_VERSION = "v1";

export const TOUR_STEPS: TourStep[] = [
  {
    id: "sidebar",
    route: "/dashboard",
    selector: '[data-tour="sidebar"]',
    title: "Navigation",
    body: "Use the sidebar to move between operational areas. Everything you see is scoped to your organization and the active store.",
  },
  {
    id: "topbar",
    route: "/dashboard",
    selector: '[data-tour="topbar"]',
    title: "Organization + store",
    body: "Switch the active store from the topbar. All listings, products, and dashboard stats update to match.",
  },
  {
    id: "widgets",
    route: "/dashboard",
    selector: '[data-tour="dashboard-widgets"]',
    title: "Dashboard widgets",
    body: "Quick visibility into inventory totals, category coverage, product types, and marketplace health.",
  },
  {
    id: "nav-listings",
    route: "/dashboard",
    selector: '[data-tour="nav-listings"]',
    title: "Go to Listings",
    body: "Next we’ll review live listings for the active store.",
  },
  {
    id: "listings",
    route: "/listings",
    selector: '[data-tour="listings"]',
    title: "Listings",
    body: "Listings represent sellable inventory in a specific store. Pricing and status are store-scoped.",
  },
  {
    id: "nav-site-editor",
    route: "/listings",
    selector: '[data-tour="nav-site-editor"]',
    title: "Open Site Editor",
    body: "Next we’ll configure the clientfront homepage for this organization.",
  },
  {
    id: "site-editor",
    route: "/site-editor",
    selector: '[data-tour="site-editor"]',
    title: "Site Editor",
    body: "Edit homepage sections like hero banners, featured products, and promotional blocks — then preview the result.",
  },
  {
    id: "take-tour",
    route: "/site-editor",
    selector: '[data-tour="take-tour"]',
    title: "Take a tour anytime",
    body: "You can restart this tour from the sidebar whenever you need a refresher.",
  },
];

