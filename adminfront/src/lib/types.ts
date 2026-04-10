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
    marketplace: unknown | null;
  };
};

