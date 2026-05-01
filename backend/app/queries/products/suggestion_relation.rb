module Products
  class SuggestionRelation
    DEFAULT_LIMIT = 10

    def initialize(query:, metadata_query: nil, limit: DEFAULT_LIMIT)
      @query = query.to_s.strip
      @metadata_query = metadata_query.to_s.strip
      @limit = limit.to_i
    end

    def call
      scope = scoped_products_relation.includes(:product_type, :category)

      if @query.present?
        scope = scope.suggest(@query)
      end

      if @metadata_query.present?
        scope = scope.where("products.search_document @@ plainto_tsquery('simple', ?)", @metadata_query)
      end

      scope.limit(@limit.positive? ? @limit : DEFAULT_LIMIT)
    end

    private

    def scoped_products_relation
      Products::ReusableRelation.call
    end

    # Avoid ILIKE scans; search_document is indexed via GIN.
  end
end
