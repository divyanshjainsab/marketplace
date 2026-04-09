module Products
  class CreateOrReuse
    Result = Struct.new(:product, :suggestions, :status, keyword_init: true)

    # Flow:
    # 1) Call with `force_create: false` to get suggestions (no insert).
    # 2) If the client selects one, call again with `reuse_product_id:`.
    # 3) If the client confirms creation, call with `force_create: true`.
    def self.call(attrs:, reuse_product_id: nil, force_create: false, suggestion_limit: 10)
      new(
        attrs: attrs,
        reuse_product_id: reuse_product_id,
        force_create: force_create,
        suggestion_limit: suggestion_limit
      ).call
    end

    def initialize(attrs:, reuse_product_id:, force_create:, suggestion_limit:)
      @attrs = attrs.to_h.symbolize_keys
      @reuse_product_id = reuse_product_id
      @force_create = force_create
      @suggestion_limit = suggestion_limit
    end

    def call
      if @reuse_product_id.present?
        product = Product.kept.find(@reuse_product_id)
        return Result.new(product: product, suggestions: [], status: :reused)
      end

      suggestions = Products::Suggest.call(
        query: @attrs[:name] || @attrs[:sku],
        metadata_query: @attrs[:metadata].is_a?(Hash) ? @attrs[:metadata].values.join(" ") : nil,
        limit: @suggestion_limit
      )

      if suggestions.any? && !@force_create
        return Result.new(product: nil, suggestions: suggestions, status: :suggestions)
      end

      product = Product.create!(@attrs.slice(:product_type_id, :category_id, :name, :sku, :metadata))
      Result.new(product: product, suggestions: suggestions, status: :created)
    end
  end
end
