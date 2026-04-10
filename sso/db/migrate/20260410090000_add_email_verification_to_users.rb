class AddEmailVerificationToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :email_verified, :boolean, null: false, default: false
    add_index :users, :email_verified
  end
end
