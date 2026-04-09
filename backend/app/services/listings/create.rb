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
        product = Product.kept.find(@params[:product_id])
        return Products::CreateOrReuse::Result.new(product: product, suggestions: [], status: :reused)
      end

      Products::CreateOrReuse.call(
        attrs: product_attributes,
        reuse_product_id: @params[:reuse_product_id],
        force_create: ActiveModel::Type::Boolean.new.cast(@params[:force_create]),
        suggestion_limit: @suggestion_limit
      )
    end

    def resolve_variant(product)
      if @params[:variant_id].present?
        variant = product.variants.kept.find(@params[:variant_id])
        return Variants::CreateOrReuse::Result.new(variant: variant, status: :reused)
      end

      Variants::CreateOrReuse.call(product_id: product.id, attrs: variant_attributes)
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
      image = @params.dig(:product, :image)
      return if image.blank?

      Images::ImageUploader.attach(
        record: product,
        io: image.tempfile,
        filename: image.original_filename,
        folder: "products",
        delete_old: true
      )
    end

    def attach_variant_image(variant)
      image = @params.dig(:variant, :image)
      return if image.blank?

      Images::ImageUploader.attach(
        record: variant,
        io: image.tempfile,
        filename: image.original_filename,
        folder: "variants",
        delete_old: true
      )
    end
  end
end

