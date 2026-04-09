class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.citext :code, null: false
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :categories, :code, unique: true, where: "discarded_at IS NULL"
    add_index :categories, :discarded_at
  end
end
