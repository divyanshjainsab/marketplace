owner = User.kept.find_or_initialize_by(external_id: "11111111-1111-1111-1111-111111111111")
owner.email = "owner@example.com"
owner.name = "Demo Owner"
owner.save!

organization = Organization.kept.find_or_create_by!(slug: "demo-org") do |record|
  record.name = "Demo Organization"
end

marketplace = Marketplace.kept.find_or_create_by!(subdomain: "demo") do |record|
  record.organization = organization
  record.name = "Demo Marketplace"
  record.custom_domain = "demo.localhost"
end

MarketplaceDomain.kept.find_or_create_by!(marketplace: marketplace, host: "demo.localhost")
OrganizationMembership.kept.find_or_create_by!(user: owner, organization: organization) do |record|
  record.role = "owner"
end
MarketplaceMembership.kept.find_or_create_by!(user: owner, marketplace: marketplace) do |record|
  record.role = "owner"
end

apparel = ProductType.kept.find_or_create_by!(code: "apparel") do |record|
  record.name = "Apparel"
end

tops = Category.kept.find_or_create_by!(code: "tops") do |record|
  record.name = "Tops"
end

product = Product.kept.find_or_create_by!(sku: "DEMO-TSHIRT") do |record|
  record.name = "Demo T-Shirt"
  record.product_type = apparel
  record.category = tops
  record.metadata = { material: "cotton", gender: "unisex" }
end

variant = Variant.kept.find_or_create_by!(sku: "DEMO-TSHIRT-BLK-M") do |record|
  record.product = product
  record.name = "Black / Medium"
  record.options = { color: "Black", size: "M" }
end

Listing.kept.find_or_create_by!(marketplace: marketplace, variant: variant) do |record|
  record.product = product
  record.price_cents = 2499
  record.currency = "USD"
  record.status = "active"
end
