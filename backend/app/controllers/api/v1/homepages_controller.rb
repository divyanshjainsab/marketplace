module Api
  module V1
    class HomepagesController < BaseController
      def show
        marketplace = Current.marketplace
        return render_error("not_found", status: :not_found, message: "Marketplace not found") if marketplace.nil?

        organization = marketplace.organization

        raw_config = Rails.cache.fetch(cache_key(organization), expires_in: 60) do
          organization.homepage_config || {}
        end

        config = SiteEditor::HomepageConfigSanitizer.call(raw: raw_config)

        featured_products = resolve_products(config["featured_products"])
        featured_listings = resolve_listings(marketplace, config["featured_listings"])
        featured_categories = resolve_categories(config["categories"])

        render json: {
          data: {
            organization: OrganizationSerializer.one(organization),
            marketplace: MarketplaceSerializer.one(marketplace),
            homepage_config: config,
            resolved: {
              featured_products: featured_products.map { |p| ProductSerializer.one(p) },
              featured_listings: featured_listings.map { |l| ListingSerializer.one(l) },
              categories: featured_categories.map { |c| CategorySerializer.one(c) }
            }
          }
        }
      end

      private

      def cache_key(organization)
        "homepage_config:org:#{organization.id}"
      end

      def resolve_products(ids)
        ids = Array(ids).map(&:to_i).select(&:positive?).uniq
        return [] if ids.empty?

        products = Product.kept.where(id: ids).includes(:category, :product_type).to_a
        products.sort_by { |p| ids.index(p.id) || ids.length }
      end

      def resolve_listings(marketplace, ids)
        ids = Array(ids).map(&:to_i).select(&:positive?).uniq
        return [] if ids.empty?

        listings = Listing.kept.where(marketplace_id: marketplace.id, id: ids).includes(:product, :variant).to_a
        listings.sort_by { |l| ids.index(l.id) || ids.length }
      end

      def resolve_categories(codes)
        codes = Array(codes).map { |c| c.to_s.strip }.reject(&:blank?).uniq
        return [] if codes.empty?

        categories = Category.kept.where(code: codes).order(:name).to_a
        categories.sort_by { |c| codes.index(c.code) || codes.length }
      end
    end
  end
end

