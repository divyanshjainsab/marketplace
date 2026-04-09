module Variants
  class CreateOrReuse
    Result = Struct.new(:variant, :status, keyword_init: true)

    def self.call(product_id:, attrs:)
      new(product_id: product_id, attrs: attrs).call
    end

    def initialize(product_id:, attrs:)
      @product = Product.kept.find(product_id)
      @attrs = attrs.to_h.symbolize_keys
    end

    def call
      variant = @product.variants.kept.find_or_initialize_by(sku: @attrs[:sku])
      variant.assign_attributes(@attrs.slice(:name, :sku, :options))
      status = variant.new_record? ? :created : :reused
      variant.save!

      Result.new(variant: variant, status: status)
    end
  end
end

