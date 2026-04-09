class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.citext :external_id, null: false
      t.string :email
      t.string :name
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :users, :external_id, unique: true, where: "discarded_at IS NULL"
    add_index :users, :discarded_at
  end
end
