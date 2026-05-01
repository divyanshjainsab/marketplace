module Listings
  class Create
    Result = Struct.new(:listing, :product, :variant, :suggestions, :status, keyword_init: true)

    def self.call(marketplace:, params:, actor:, suggestion_limit: 10)
      new(
        marketplace: marketplace,
        params: params,
        actor: actor,
        suggestion_limit: suggestion_limit
      ).call
    end

    def initialize(marketplace:, params:, actor:, suggestion_limit:)
      @marketplace = marketplace
      @params = params.deep_symbolize_keys
      @actor = actor
      @suggestion_limit = suggestion_limit
    end

    def call
      PaperTrail.request(whodunnit: @actor&.external_id) do
        ActiveRecord::Base.transaction do
          product_result = resolve_product
          return Result.new(suggestions: product_result.suggestions, status: :suggestions) if product_result.status == :suggestions

          product = product_result.product
          attach_product_image(product)

          variant_result = resolve_variant(product)
          variant = variant_result.variant
          attach_variant_image(variant)

          listing = @marketplace.listings.kept.find_or_initialize_by(variant: variant)
          listing.product = product
          listing.assign_attributes(listing_attributes)
          listing.save!
          update_inventory_if_requested!(listing)
          attach_listing_image(listing)

          Result.new(
            listing: listing,
            product: product,
            variant: variant,
            suggestions: product_result.suggestions,
            status: listing.previously_new_record? ? :created : :reused
          )
        end
      end
    end

    private

    def resolve_product
      if @params[:product_id].present?
        product = reusable_products_relation.find(@params[:product_id])
        return Products::CreateOrReuse::Result.new(product: product, suggestions: [], status: :reused)
      end

      Products::CreateOrReuse.call(
        attrs: product_attributes,
        reuse_product_id: @params[:reuse_product_id],
        force_create: ActiveModel::Type::Boolean.new.cast(@params[:force_create]),
        suggestion_limit: @suggestion_limit
      )
    end

    def reusable_products_relation
      Product.kept
        .joins(:listings)
        .merge(Listing.kept.where(marketplace_id: @marketplace.id))
        .distinct
    end

    def resolve_variant(product)
      if @params[:variant_id].present?
        variant = product.variants.kept.find(@params[:variant_id])
        return Variants::CreateOrReuse::Result.new(variant: variant, status: :reused)
      end

      Variants::CreateOrReuse.call(product: product, attrs: variant_attributes)
    end

    def listing_attributes
      @params.slice(:price_cents, :currency, :status)
    end

    def product_attributes
      (@params[:product] || {}).slice(:product_type_id, :category_id, :name, :sku, :metadata)
    end

    def variant_attributes
      (@params[:variant] || {}).slice(:name, :sku, :options)
    end

    def attach_product_image(product)
      folder = Images::FolderPath.for(target: :product, organization: organization)
      tags = Images::FolderPath.tags(target: :product, organization: organization)

      image = @params.dig(:product, :image)
      if image.present?
        Images::ImageAttachment.attach_upload(
          record: product,
          uploaded_file: image,
          folder: folder,
          tags: tags,
          delete_old: true,
          organization_id: organization.id,
          marketplace_id: @marketplace.id,
          request_host: Current.request_host
        )
        return
      end

      image_data = @params.dig(:product, :image_data)
      return if image_data.blank?

      Images::ImageAttachment.replace(
        record: product,
        asset_payload: image_data,
        folder_prefix: folder,
        delete_old: true,
        organization_id: organization.id,
        marketplace_id: @marketplace.id,
        request_host: Current.request_host
      )
    end

    def attach_variant_image(variant)
      folder = Images::FolderPath.for(target: :variant, organization: organization)
      tags = Images::FolderPath.tags(target: :variant, organization: organization)

      image = @params.dig(:variant, :image)
      if image.present?
        Images::ImageAttachment.attach_upload(
          record: variant,
          uploaded_file: image,
          folder: folder,
          tags: tags,
          delete_old: true,
          organization_id: organization.id,
          marketplace_id: @marketplace.id,
          request_host: Current.request_host
        )
        return
      end

      image_data = @params.dig(:variant, :image_data)
      return if image_data.blank?

      Images::ImageAttachment.replace(
        record: variant,
        asset_payload: image_data,
        folder_prefix: folder,
        delete_old: true,
        organization_id: organization.id,
        marketplace_id: @marketplace.id,
        request_host: Current.request_host
      )
    end

    def attach_listing_image(listing)
      folder = Images::FolderPath.for(target: :listing, organization: organization, marketplace: @marketplace)
      tags = Images::FolderPath.tags(target: :listing, organization: organization, marketplace: @marketplace)

      image = @params[:image]
      if image.present?
        Images::ImageAttachment.attach_upload(
          record: listing,
          uploaded_file: image,
          folder: folder,
          tags: tags,
          delete_old: true,
          organization_id: organization.id,
          marketplace_id: @marketplace.id,
          request_host: Current.request_host
        )
        return
      end

      image_data = @params[:image_data]
      return if image_data.blank?

      Images::ImageAttachment.replace(
        record: listing,
        asset_payload: image_data,
        folder_prefix: folder,
        delete_old: true,
        organization_id: organization.id,
        marketplace_id: @marketplace.id,
        request_host: Current.request_host
      )
    end

    def organization
      @organization ||= @marketplace.organization
    end

    def update_inventory_if_requested!(listing)
      return unless @params.key?(:inventory_count)

      inventory = listing.inventory || listing.build_inventory(marketplace: @marketplace)
      inventory.quantity_on_hand = @params[:inventory_count].to_i
      inventory.save!
    end
  end
end
