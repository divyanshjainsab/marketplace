class ScopeCategoriesToProductType < ActiveRecord::Migration[7.1]
  def change
    add_reference :categories, :product_type, null: true, foreign_key: true, index: true

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE categories
          SET product_type_id = products_by_category.product_type_id
          FROM (
            SELECT category_id, MIN(product_type_id) AS product_type_id
            FROM products
            WHERE category_id IS NOT NULL
            GROUP BY category_id
          ) AS products_by_category
          WHERE categories.id = products_by_category.category_id
            AND categories.product_type_id IS NULL;
        SQL

        execute <<~SQL.squish
          DO $$
          DECLARE default_product_type_id bigint;
          BEGIN
            SELECT id
            INTO default_product_type_id
            FROM product_types
            WHERE discarded_at IS NULL
            ORDER BY id
            LIMIT 1;

            IF default_product_type_id IS NOT NULL THEN
              UPDATE categories
              SET product_type_id = default_product_type_id
              WHERE product_type_id IS NULL;
            END IF;
          END $$;
        SQL
      end
    end

    change_column_null :categories, :product_type_id, false

    remove_index :categories, name: "index_categories_on_code"
    add_index :categories,
              %i[product_type_id code],
              unique: true,
              where: "discarded_at IS NULL",
              name: "index_categories_on_product_type_and_code_active"
  end
end

