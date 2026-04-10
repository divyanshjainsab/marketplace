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
  organization_id: number;
};

export type SessionResponse = {
  data: {
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
