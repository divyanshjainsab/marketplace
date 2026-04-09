class AddProductSearchFields < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :metadata, :jsonb, null: false, default: {}, if_not_exists: true

    # Weighted search document for fast suggestions.
    # Includes name + sku + free-form metadata text.
    add_column :products,
               :search_document,
               :tsvector,
               if_not_exists: true,
               stored: true,
               as: <<~SQL.squish
                 setweight(to_tsvector('simple', coalesce(name, '')), 'A') ||
                 setweight(to_tsvector('simple', coalesce(sku, '')), 'A') ||
                 setweight(to_tsvector('simple', coalesce(metadata::text, '')), 'B')
               SQL

    add_index :products, :metadata, using: :gin, if_not_exists: true
    add_index :products, :search_document, using: :gin, if_not_exists: true

    execute <<~SQL
      CREATE INDEX IF NOT EXISTS index_products_on_name_trgm_active
      ON products
      USING gin (name gin_trgm_ops)
      WHERE discarded_at IS NULL;
    SQL

    execute <<~SQL
      CREATE INDEX IF NOT EXISTS index_products_on_sku_trgm_active
      ON products
      USING gin (sku gin_trgm_ops)
      WHERE discarded_at IS NULL;
    SQL
  end
end
