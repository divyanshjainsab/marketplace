class AddConsumedTimestepToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :consumed_timestep, :integer, null: false, default: 0
  end
end

