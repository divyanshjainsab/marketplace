class CreateAddresses < ActiveRecord::Migration[7.1]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :address_type, null: false
      t.string :line1, null: false
      t.string :line2
      t.string :city, null: false
      t.string :state, null: false
      t.string :country, null: false
      t.string :zip_code, null: false
      t.datetime :discarded_at
      t.timestamps
    end

    add_index :addresses, :discarded_at

    # Prevent accidental duplicates among "active" addresses.
    add_index(
      :addresses,
      %i[user_id address_type line1 line2 city state country zip_code],
      unique: true,
      where: "discarded_at IS NULL",
      name: "idx_addresses_unique_active"
    )
  end
end

