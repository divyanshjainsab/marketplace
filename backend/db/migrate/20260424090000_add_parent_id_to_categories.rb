class AddParentIdToCategories < ActiveRecord::Migration[7.1]
  def change
    add_reference :categories, :parent, foreign_key: { to_table: :categories }, index: true, null: true
  end
end

