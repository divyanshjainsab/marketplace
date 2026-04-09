module Products
  class Suggest
    Suggestion = Struct.new(
      :product_id,
      :name,
      :sku,
      :product_type,
      :category,
      :metadata,
      keyword_init: true
    )

    def self.call(query:, metadata_query: nil, limit: 10)
      new(query: query, metadata_query: metadata_query, limit: limit).call
    end

    def initialize(query:, metadata_query: nil, limit: 10)
      @relation = SuggestionRelation.new(query: query, metadata_query: metadata_query, limit: limit)
    end

    def call
      @relation.call.map do |product|
        Suggestion.new(
          product_id: product.id,
          name: product.name,
          sku: product.sku,
          product_type: product.product_type&.name,
          category: product.category&.name,
          metadata: product.metadata
        )
      end
    end
  end
end
