class AddVariantOptionsIndexesAndDigest < ActiveRecord::Migration[7.1]
  def change
    add_column :variants,
               :options_digest,
               :string,
               if_not_exists: true,
               stored: true,
               as: "md5(coalesce(options, '{}'::jsonb)::text)"

    add_index :variants, :options, using: :gin, if_not_exists: true
    add_index :variants,
              %i[product_id options_digest],
              unique: true,
              where: "discarded_at IS NULL",
              name: "index_variants_on_product_and_options_digest_active"
  end
end

