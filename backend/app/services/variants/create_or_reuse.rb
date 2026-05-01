module Variants
  class CreateOrReuse
    Result = Struct.new(:variant, :status, keyword_init: true)

    def self.call(product:, attrs:)
      new(product: product, attrs: attrs).call
    end

    def initialize(product:, attrs:)
      @product = product
      @attrs = attrs.to_h.symbolize_keys
    end

    def call
      options = normalize_options(@attrs[:options])
      existing_by_options = find_existing_variant_by_options(options)

      if existing_by_options.present?
        existing_by_options.assign_attributes(@attrs.slice(:name))
        existing_by_options.save! if existing_by_options.changed?
        return Result.new(variant: existing_by_options, status: :reused)
      end

      variant = @product.variants.kept.find_or_initialize_by(sku: @attrs[:sku])
      variant.assign_attributes(@attrs.slice(:name, :sku))
      variant.options = options
      status = variant.new_record? ? :created : :reused

      begin
        variant.save!
      rescue ActiveRecord::RecordNotUnique
        existing_by_options = find_existing_variant_by_options(options)
        raise if existing_by_options.blank?

        return Result.new(variant: existing_by_options, status: :reused)
      end

      Result.new(variant: variant, status: status)
    end

    private

    def normalize_options(value)
      hash =
        if value.respond_to?(:to_h)
          value.to_h
        elsif value.is_a?(Hash)
          value
        else
          {}
        end

      hash.deep_stringify_keys
    end

    def find_existing_variant_by_options(options)
      @product.variants.kept.find_by("options_digest = md5(?::jsonb::text)", options.to_json)
    end
  end
end
