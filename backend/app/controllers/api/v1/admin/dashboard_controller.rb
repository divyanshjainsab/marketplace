module Api
  module V1
    module Admin
      class DashboardController < BaseController
        before_action only: :show do
          require_admin_permission!("view_dashboard")
        end

        def show
          data = Rails.cache.fetch(cache_key, expires_in: 15) do
            build_dashboard
          end

          render json: { data: data }
        end

        private

        def cache_key
          "admin:dashboard:org:#{current_organization.id}:marketplace:#{current_marketplace.id}"
        end

        def build_dashboard
          listings = Listing.kept
            .where(marketplace_id: current_marketplace.id)
            .includes(:product, :variant)

          total_listings = listings.count
          total_products = listings.select(:product_id).distinct.count

          product_ids = listings.select(:product_id).distinct
          category_counts = Product.kept.where(id: product_ids).group(:category_id).count
          categories = Category.kept.where(id: category_counts.keys).order(:name)

          product_type_counts = Product.kept.where(id: product_ids).group(:product_type_id).count
          product_types = ProductType.kept.where(id: product_type_counts.keys).order(:name)

          listing_status_counts = listings.group(:status).count

          recent_activity = listings
            .order(updated_at: :desc)
            .limit(10)
            .map do |listing|
              {
                type: "listing",
                id: listing.id,
                label: "#{listing.product&.name} — #{listing.variant&.name}",
                status: listing.status,
                updated_at: listing.updated_at.iso8601
              }
            end

          {
            organization: OrganizationSerializer.one(current_organization),
            marketplace: MarketplaceSerializer.one(current_marketplace),
            totals: {
              products: total_products,
              listings: total_listings
            },
            category_distribution: categories.map do |category|
              {
                category: CategorySerializer.one(category),
                product_count: category_counts[category.id] || 0
              }
            end,
            product_type_distribution: product_types.map do |product_type|
              {
                product_type: ProductTypeSerializer.one(product_type),
                product_count: product_type_counts[product_type.id] || 0
              }
            end,
            listing_status_distribution: listing_status_counts.map do |status, count|
              { status: status.presence || "unknown", listing_count: count }
            end.sort_by { |row| row[:status].to_s },
            recent_activity: recent_activity,
            marketplace_status: {
              id: current_marketplace.id,
              name: current_marketplace.name,
              custom_domain: current_marketplace.custom_domain
            }
          }
        end
      end
    end
  end
end
