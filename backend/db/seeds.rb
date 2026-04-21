def seed_user!(external_id:, email:, name:, roles:)
  user = User.kept.find_or_initialize_by(external_id: external_id)
  user.email = email
  user.name = name
  user.roles = Array(roles)
  user.save! if user.changed?
  user
end

def seed_organization!(slug:, name:, subdomain:, dev_port:)
  organization = Organization.kept.find_or_initialize_by(slug: slug)
  organization.name = name
  organization.subdomain = subdomain
  organization.dev_port = dev_port
  organization.save! if organization.changed?
  organization
end

def seed_marketplace!(organization:, subdomain:, name:, custom_domain:)
  Marketplace.kept.find_or_create_by!(subdomain: subdomain) do |record|
    record.organization = organization
    record.name = name
    record.custom_domain = custom_domain
  end
end

def seed_marketplace_domain!(marketplace:, host:)
  MarketplaceDomain.kept.find_or_create_by!(marketplace: marketplace, host: host)
end

def seed_org_membership!(user:, organization:, role:)
  OrganizationMembership.kept.find_or_create_by!(user: user, organization: organization) do |record|
    record.role = role
  end
end

def seed_marketplace_membership!(user:, marketplace:, role:)
  MarketplaceMembership.kept.find_or_create_by!(user: user, marketplace: marketplace) do |record|
    record.role = role
  end
end

def seed_listing!(marketplace:, sku_prefix:, category_code:, category_name:)
  apparel = ProductType.kept.find_or_create_by!(code: "apparel") do |record|
    record.name = "Apparel"
  end

  category = Category.kept.find_or_create_by!(code: category_code) do |record|
    record.name = category_name
  end

  product = Product.kept.find_or_create_by!(sku: "#{sku_prefix}-PRODUCT") do |record|
    record.name = "#{sku_prefix} Product"
    record.product_type = apparel
    record.category = category
    record.metadata = { seeded: true, org: sku_prefix.downcase }
  end

  variant = Variant.kept.find_or_create_by!(sku: "#{sku_prefix}-VARIANT") do |record|
    record.product = product
    record.name = "#{sku_prefix} Variant"
    record.options = { seeded: true }
  end

  Listing.kept.find_or_create_by!(marketplace: marketplace, variant: variant) do |record|
    record.product = product
    record.price_cents = 2499
    record.currency = "INR"
    record.status = "active"
  end
end

# Admin / RBAC test users (external IDs must match SSO seeds)
super_admin = seed_user!(
  external_id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  email: "superadmin@test.com",
  name: "Super Admin",
  roles: %w[super_admin]
)

org_admin_a = seed_user!(
  external_id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
  email: "adminA@test.com",
  name: "Org Admin A",
  roles: []
)

org_admin_b = seed_user!(
  external_id: "cccccccc-cccc-cccc-cccc-cccccccccccc",
  email: "adminB@test.com",
  name: "Org Admin B",
  roles: []
)

seed_user!(
  external_id: "dddddddd-dddd-dddd-dddd-dddddddddddd",
  email: "user@test.com",
  name: "Normal User",
  roles: []
)

# Organizations + marketplaces
org_a = seed_organization!(slug: "org1", name: "Organization 1", subdomain: "org1", dev_port: 3000)
org_b = seed_organization!(slug: "org2", name: "Organization 2", subdomain: "org2", dev_port: 3003)

marketplace_a = seed_marketplace!(
  organization: org_a,
  subdomain: "org1",
  name: "Org 1 Marketplace",
  custom_domain: "org1.localhost"
)
marketplace_b = seed_marketplace!(
  organization: org_b,
  subdomain: "org2",
  name: "Org 2 Marketplace",
  custom_domain: "org2.localhost"
)

seed_marketplace_domain!(marketplace: marketplace_a, host: "org1.localhost")
seed_marketplace_domain!(marketplace: marketplace_b, host: "org2.localhost")

seed_org_membership!(user: org_admin_a, organization: org_a, role: "admin")
seed_marketplace_membership!(user: org_admin_a, marketplace: marketplace_a, role: "admin")

seed_org_membership!(user: org_admin_b, organization: org_b, role: "admin")
seed_marketplace_membership!(user: org_admin_b, marketplace: marketplace_b, role: "admin")

# Seed explicit memberships for the super admin to keep environments usable even if
# super admin bypass is disabled.
seed_org_membership!(user: super_admin, organization: org_a, role: "owner")
seed_marketplace_membership!(user: super_admin, marketplace: marketplace_a, role: "owner")
seed_org_membership!(user: super_admin, organization: org_b, role: "owner")
seed_marketplace_membership!(user: super_admin, marketplace: marketplace_b, role: "owner")

# Sample listings/products per org for isolation verification.
seed_listing!(marketplace: marketplace_a, sku_prefix: "ORGA", category_code: "org_a_category", category_name: "Org A Category")
seed_listing!(marketplace: marketplace_b, sku_prefix: "ORGB", category_code: "org_b_category", category_name: "Org B Category")

puts "Seeded backend organizations: org1, org2"
puts "Tenant dev ports: org1=3000, org2=3003"
puts "Seeded backend users: superadmin@test.com, adminA@test.com, adminB@test.com, user@test.com"
