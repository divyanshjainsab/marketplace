module Products
  class SuggestionRelation
    DEFAULT_LIMIT = 10

    def initialize(query:, metadata_query: nil, limit: DEFAULT_LIMIT)
      @query = query.to_s.strip
      @metadata_query = metadata_query.to_s.strip
      @limit = limit.to_i
    end

    def call
      scope = Product.kept.includes(:product_type, :category)

      if @query.present?
        scope = scope.suggest(@query)
      end

      if @metadata_query.present?
        scope = scope.where("products.metadata::text ILIKE ?", "%#{sanitize_like(@metadata_query)}%")
      end

      scope.limit(@limit.positive? ? @limit : DEFAULT_LIMIT)
    end

    private

    def sanitize_like(value)
      ActiveRecord::Base.sanitize_sql_like(value)
    end
  end
end
