class CreateSiteEditorV2Core < ActiveRecord::Migration[7.1]
  def change
    create_table :searches do |t|
      t.text :search_params
      t.string :type
      t.bigint :market_place_id
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :searches, :type
    add_index :searches, :market_place_id

    create_table :pages do |t|
      t.string :name
      t.string :title
      t.string :slug
      t.references :market_place, null: true, foreign_key: { to_table: :marketplaces }
      t.boolean :template, default: false
      t.datetime :deleted_at
      t.boolean :v2, default: true

      t.timestamps
    end

    add_index :pages, [:market_place_id, :slug, :v2], unique: true, name: "index_pages_on_market_place_id_slug_v2"
    add_index :pages, :deleted_at

    create_table :landing_components do |t|
      t.bigint :search_id
      t.text :items_ids
      t.integer :type_component
      t.integer :items_type
      t.string :title
      t.integer :row_index, default: 0, null: false
      t.string :components_id
      t.bigint :components_group_landing_id
      t.text :serialized_content
      t.datetime :deleted_at
      t.references :page, null: true, foreign_key: true
      t.bigint :parent_components_id

      t.timestamps
    end

    add_index :landing_components, :search_id
    add_index :landing_components, :components_group_landing_id
    add_index :landing_components, :parent_components_id
    add_index :landing_components, :deleted_at

    create_table :market_place_options do |t|
      t.string :primary_color_main
      t.string :primary_color_dark
      t.string :secondary_color_main
      t.string :secondary_color_dark
      t.string :background_color_main
      t.string :background_color_dark
      t.bigint :market_place_id
      t.string :typography_color_main
      t.string :typography_color_dark
      t.integer :height
      t.integer :width
      t.string :dark_primary_color_main, default: "#1E8BB5"
      t.string :dark_primary_color_dark, default: "#16698A"
      t.string :dark_secondary_color_main, default: "#79A93C"
      t.string :dark_secondary_color_dark, default: "#4E6D29"
      t.string :dark_background_color_main, default: "#121212"
      t.string :dark_background_color_dark, default: "#1E1E1E"
      t.string :dark_typography_color_main, default: "#FFFFFF"
      t.string :dark_typography_color_dark, default: "#B3B3B3"
      t.string :colorable_type
      t.bigint :colorable_id
      t.string :header_background_color_main, default: "#2EBAE8"
      t.string :header_background_color_dark, default: "#2595ba"
      t.string :header_typography_color_main, default: "#0D0D0D"
      t.string :header_typography_color_dark, default: "#042636"
      t.string :dark_header_background_color_main, default: "#1E8BB5"
      t.string :dark_header_background_color_dark, default: "#16698A"
      t.string :dark_header_typography_color_main, default: "#FFFFFF"
      t.string :dark_header_typography_color_dark, default: "#B3B3B3"
      t.jsonb :header_content, default: {
        "blocks" => [
          {
            "key" => "siteeditor",
            "data" => { "text-align" => "center" },
            "text" => "Customize your header text",
            "type" => "unstyled",
            "depth" => 0,
            "entityRanges" => [],
            "inlineStyleRanges" => [
              { "style" => "color-rgb(255,255,255)", "length" => 26, "offset" => 0 }
            ]
          }
        ],
        "entityMap" => {}
      }
      t.datetime :deleted_at
      t.boolean :use_infinite_scroll, default: false

      t.timestamps
    end

    add_index :market_place_options, :market_place_id
    add_index :market_place_options, [:colorable_type, :colorable_id], name: "index_market_place_options_on_colorable"
    add_index :market_place_options, :deleted_at

    create_table :slides do |t|
      t.string :title
      t.string :subtitle
      t.bigint :jumbotron_id
      t.string :button_label
      t.string :button_url
      t.bigint :landing_component_id
      t.string :image_align
      t.datetime :deleted_at
      t.string :image_url, default: ""
      t.string :mobile_image_url, default: ""
      t.uuid :stored_file_uuid
      t.string :categorizable_type
      t.bigint :categorizable_id
      t.text :product_items_ids

      t.timestamps
    end

    add_index :slides, :landing_component_id
    add_index :slides, :jumbotron_id
    add_index :slides, [:categorizable_type, :categorizable_id], name: "index_slides_on_categorizable"
    add_index :slides, :deleted_at

    create_table :assets do |t|
      t.string :name
      t.text :tags
      t.references :market_place, null: true, foreign_key: { to_table: :marketplaces }
      t.references :recordable, polymorphic: true, null: false
      t.datetime :deleted_at
      t.boolean :is_cc_template, default: false, null: false
      t.boolean :is_promo_template, default: false, null: false
      t.boolean :is_network, default: false

      t.timestamps
    end

    add_index :assets, :deleted_at

    create_table :page_versions do |t|
      t.references :page, null: false, foreign_key: true
      t.integer :version_number, null: false
      t.jsonb :snapshot, null: false, default: {}
      t.string :created_by
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :page_versions, [:page_id, :version_number], unique: true
    add_index :page_versions, :deleted_at
  end
end
