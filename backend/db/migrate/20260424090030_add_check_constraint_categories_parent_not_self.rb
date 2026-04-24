class AddCheckConstraintCategoriesParentNotSelf < ActiveRecord::Migration[7.1]
  def change
    add_check_constraint :categories, "parent_id IS NULL OR parent_id <> id", name: "categories_parent_id_not_self"
  end
end

