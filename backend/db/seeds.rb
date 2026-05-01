def seed_user!(external_id:, email:, name:, roles:)
  user = User.kept.find_or_initialize_by(external_id: external_id)
  user.email = email
  user.name = name
  user.roles = Array(roles)
  user.save! if user.changed?
  user
end

def seed_organization!(slug:, name:, subdomain:)
  organization = Organization.kept.find_or_initialize_by(slug: slug)
  organization.name = name
  organization.subdomain = subdomain
  organization.save! if organization.changed?
  organization
end

def seed_marketplace!(organization:, name:, custom_domain:)
  marketplace = Marketplace.kept.find_or_initialize_by(custom_domain: custom_domain)
  marketplace.organization = organization
  marketplace.name = name
  marketplace.custom_domain = custom_domain
  marketplace.save! if marketplace.changed?
  marketplace
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
  clothing = seed_product_type!(code: "clothing", name: "Clothing")

  category = Category.kept.find_or_create_by!(product_type: clothing, code: category_code) do |record|
    record.name = category_name
  end

  product = Product.kept.find_or_create_by!(sku: "#{sku_prefix}-PRODUCT") do |record|
    record.name = "#{sku_prefix} Product"
    record.product_type = clothing
    record.category = category
    record.metadata = { brand: sku_prefix, material: "Cotton", fit: "Regular" }
  end

  variant = Variant.kept.find_or_create_by!(sku: "#{sku_prefix}-VARIANT") do |record|
    record.product = product
    record.name = "#{sku_prefix} Variant"
    record.options = { size: "M", color: "Black" }
  end

  Listing.kept.find_or_create_by!(marketplace: marketplace, variant: variant) do |record|
    record.product = product
    record.price_cents = 2499
    record.currency = "INR"
    record.status = "active"
    record.inventory_count = 25
  end
end

def seed_product_type!(code:, name:)
  ProductType.kept.find_or_create_by!(code: code) do |record|
    record.name = name
  end
end

def seed_catalog_attribute!(code:, name:, data_type:, description: nil)
  attr = CatalogAttribute.kept.find_or_initialize_by(code: code)
  attr.name = name
  attr.data_type = data_type
  attr.description = description
  attr.save! if attr.changed?
  attr
end

def seed_product_type_attribute!(product_type:, attribute:, required:, variant_level:, position:, config: {})
  record = ProductTypeAttribute.kept.find_or_initialize_by(product_type: product_type, attribute_id: attribute.id)
  record.required = required
  record.variant_level = variant_level
  record.position = position
  record.config = config
  record.save! if record.changed?
  record
end

def seed_category!(product_type:, code:, name:, parent: nil)
  resolved_product_type = parent&.product_type || product_type

  Category.kept.find_or_create_by!(product_type: resolved_product_type, code: code) do |record|
    record.name = name
    record.parent = parent
  end
end

def seed_admin_settings!(organization:, settings:)
  organization.update_admin_settings!(organization.normalized_admin_settings.deep_merge(settings.deep_stringify_keys))
end

def seed_apparel_product!(sku:, name:, category:, metadata:)
  clothing = seed_product_type!(code: "clothing", name: "Clothing")

  Product.kept.find_or_create_by!(sku: sku) do |record|
    record.name = name
    record.product_type = clothing
    record.category = category
    record.metadata = metadata
  end
end

def seed_variant!(product:, sku:, name:, options:)
  Variant.kept.find_or_create_by!(sku: sku) do |record|
    record.product = product
    record.name = name
    record.options = options
  end
end

def seed_listing_for_variant!(marketplace:, product:, variant:, price_cents:, inventory_count:)
  Listing.kept.find_or_create_by!(marketplace: marketplace, variant: variant) do |record|
    record.product = product
    record.price_cents = price_cents
    record.currency = "INR"
    record.status = "active"
    record.inventory_count = inventory_count
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

staff_user = seed_user!(
  external_id: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
  email: "staff@test.com",
  name: "Staff User",
  roles: []
)

# Organizations + marketplaces
org_a = seed_organization!(slug: "org1", name: "Organization 1", subdomain: "org1")
org_b = seed_organization!(slug: "org2", name: "Organization 2", subdomain: "org2")
org_c = seed_organization!(slug: "org3", name: "Organization 3", subdomain: "org3")

marketplace_a = seed_marketplace!(
  organization: org_a,
  name: "Org 1 Marketplace",
  custom_domain: "localhost:3002"
)
marketplace_b = seed_marketplace!(
  organization: org_b,
  name: "Org 2 Marketplace",
  custom_domain: "localhost:3003"
)
marketplace_c = seed_marketplace!(
  organization: org_c,
  name: "Org 3 Marketplace",
  custom_domain: "localhost:3004"
)

seed_admin_settings!(
  organization: org_a,
  settings: {
    general: {
      store_name: "Organization 1 Control Room",
      branding: "Global catalog enabled for collaborative merchandising."
    },
    product_settings: {
      allow_product_sharing: true,
      isolation_mode: false
    },
    integrations: {
      google_analytics_id: "G-ORG1ADMIN",
      meta_pixel_id: "PIXEL-ORG1"
    }
  }
)

seed_admin_settings!(
  organization: org_b,
  settings: {
    general: {
      store_name: "Organization 2 Control Room",
      branding: "Organization-only catalog sharing."
    },
    product_settings: {
      allow_product_sharing: true,
      isolation_mode: true
    }
  }
)

seed_admin_settings!(
  organization: org_c,
  settings: {
    general: {
      store_name: "Organization 3 Control Room",
      branding: "Strictly isolated catalog."
    },
    product_settings: {
      allow_product_sharing: false,
      isolation_mode: true
    }
  }
)

# custom_domain is the single source of truth for tenant resolution.

seed_org_membership!(user: org_admin_a, organization: org_a, role: "admin")
seed_marketplace_membership!(user: org_admin_a, marketplace: marketplace_a, role: "admin")

seed_org_membership!(user: org_admin_b, organization: org_b, role: "admin")
seed_marketplace_membership!(user: org_admin_b, marketplace: marketplace_b, role: "admin")

seed_org_membership!(user: staff_user, organization: org_a, role: "staff")
seed_marketplace_membership!(user: staff_user, marketplace: marketplace_a, role: "staff")

# Seed explicit memberships for the super admin to keep environments usable even if
# super admin bypass is disabled.
seed_org_membership!(user: super_admin, organization: org_a, role: "owner")
seed_marketplace_membership!(user: super_admin, marketplace: marketplace_a, role: "owner")
seed_org_membership!(user: super_admin, organization: org_b, role: "owner")
seed_marketplace_membership!(user: super_admin, marketplace: marketplace_b, role: "owner")
seed_org_membership!(user: super_admin, organization: org_c, role: "owner")
seed_marketplace_membership!(user: super_admin, marketplace: marketplace_c, role: "owner")

# Sample listings/products per org for isolation verification.
seed_listing!(marketplace: marketplace_a, sku_prefix: "ORGA", category_code: "org_a_category", category_name: "Org A Category")
seed_listing!(marketplace: marketplace_b, sku_prefix: "ORGB", category_code: "org_b_category", category_name: "Org B Category")
seed_listing!(marketplace: marketplace_c, sku_prefix: "ORGC", category_code: "org_c_category", category_name: "Org C Category")

# Default admin taxonomy required for listing creation.
clothing = seed_product_type!(code: "clothing", name: "Clothing")
seed_product_type!(code: "electronics", name: "Electronics")
seed_product_type!(code: "grocery", name: "Grocery")

brand = seed_catalog_attribute!(code: "brand", name: "Brand", data_type: "string")
material = seed_catalog_attribute!(code: "material", name: "Material", data_type: "string")
fit = seed_catalog_attribute!(code: "fit", name: "Fit", data_type: "enum")
size = seed_catalog_attribute!(code: "size", name: "Size", data_type: "enum")
color = seed_catalog_attribute!(code: "color", name: "Color", data_type: "string")

seed_product_type_attribute!(product_type: clothing, attribute: brand, required: false, variant_level: false, position: 10)
seed_product_type_attribute!(product_type: clothing, attribute: material, required: false, variant_level: false, position: 20)
seed_product_type_attribute!(
  product_type: clothing,
  attribute: fit,
  required: false,
  variant_level: false,
  position: 30,
  config: { allowed_values: %w[Regular Slim Relaxed] }
)
seed_product_type_attribute!(
  product_type: clothing,
  attribute: size,
  required: true,
  variant_level: true,
  position: 10,
  config: { allowed_values: %w[XS S M L XL XXL] }
)
seed_product_type_attribute!(product_type: clothing, attribute: color, required: true, variant_level: true, position: 20)

seed_category!(product_type: clothing, code: "men", name: "Men")
seed_category!(product_type: clothing, code: "women", name: "Women")
seed_category!(product_type: clothing, code: "kids", name: "Kids")
seed_category!(product_type: clothing, code: "t_shirts", name: "T-Shirts")
seed_category!(product_type: clothing, code: "shirts", name: "Shirts")
seed_category!(product_type: clothing, code: "jeans", name: "Jeans")

# India-focused apparel taxonomy + a multi-variant product to exercise PDP + cart.
men = seed_category!(product_type: clothing, code: "men", name: "Men")
women = seed_category!(product_type: clothing, code: "women", name: "Women")
kids = seed_category!(product_type: clothing, code: "kids", name: "Kids")

men_tshirts = seed_category!(product_type: clothing, code: "men_tshirts", name: "T-Shirts", parent: men)
women_dresses = seed_category!(product_type: clothing, code: "women_dresses", name: "Dresses", parent: women)

cotton_tee = seed_apparel_product!(
  sku: "TEE-COTTON-001",
  name: "Cotton Crew Neck Tee",
  category: men_tshirts,
  metadata: { brand: "Acme", material: "Cotton", fit: "Regular" }
)

tee_variants = [
  { size: "S", color: "Black" },
  { size: "M", color: "Black" },
  { size: "L", color: "Black" },
  { size: "S", color: "White" },
  { size: "M", color: "White" },
  { size: "L", color: "White" }
].map do |attrs|
  sku = "TEE-COTTON-001-#{attrs.fetch(:size)}-#{attrs.fetch(:color).upcase}"
  seed_variant!(
    product: cotton_tee,
    sku: sku,
    name: "#{attrs.fetch(:size)} / #{attrs.fetch(:color)}",
    options: { size: attrs.fetch(:size), color: attrs.fetch(:color) }
  )
end

tee_variants.each do |variant|
  seed_listing_for_variant!(
    marketplace: marketplace_a,
    product: cotton_tee,
    variant: variant,
    price_cents: 799,
    inventory_count: 20
  )
end

puts "Seeded backend organizations: org1, org2, org3"
puts "Tenant custom domains: org1=localhost:3002, org2=localhost:3003, org3=localhost:3004"
puts "Seeded backend users: superadmin@test.com, adminA@test.com, adminB@test.com, user@test.com, staff@test.com"
