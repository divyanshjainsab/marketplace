class RemoveMarketplaceSubdomainAndHardenCustomDomain < ActiveRecord::Migration[7.1]
  def up
    # Backfill any legacy rows before dropping `subdomain`.
    execute <<~SQL.squish
      UPDATE marketplaces
      SET custom_domain = lower(trim(subdomain))
      WHERE (custom_domain IS NULL OR custom_domain = '')
        AND subdomain IS NOT NULL
        AND subdomain <> '';
    SQL

    missing = select_value("SELECT COUNT(*) FROM marketplaces WHERE custom_domain IS NULL OR custom_domain = ''").to_i
    raise "marketplaces.custom_domain must be present for tenant resolution (missing: #{missing})" if missing.positive?

    if index_exists?(:marketplaces, :custom_domain, name: "index_marketplaces_on_custom_domain")
      remove_index :marketplaces, name: "index_marketplaces_on_custom_domain"
    end

    change_column_null :marketplaces, :custom_domain, false

    add_index :marketplaces,
              :custom_domain,
              unique: true,
              where: "discarded_at IS NULL",
              name: "index_marketplaces_on_custom_domain"

    if index_exists?(:marketplaces, :subdomain, name: "index_marketplaces_on_subdomain")
      remove_index :marketplaces, name: "index_marketplaces_on_subdomain"
    end

    remove_column :marketplaces, :subdomain
  end

  def down
    add_column :marketplaces, :subdomain, :citext
    add_index :marketplaces,
              :subdomain,
              unique: true,
              where: "discarded_at IS NULL",
              name: "index_marketplaces_on_subdomain"

    change_column_null :marketplaces, :custom_domain, true

    if index_exists?(:marketplaces, :custom_domain, name: "index_marketplaces_on_custom_domain")
      remove_index :marketplaces, name: "index_marketplaces_on_custom_domain"
    end

    add_index :marketplaces,
              :custom_domain,
              unique: true,
              where: "custom_domain IS NOT NULL AND discarded_at IS NULL",
              name: "index_marketplaces_on_custom_domain"
  end
end

