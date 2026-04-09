class AddDeviseTwoFactorToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :encrypted_otp_secret, :string
    add_column :users, :encrypted_otp_secret_iv, :string
    add_column :users, :encrypted_otp_secret_salt, :string
    add_column :users, :otp_required_for_login, :boolean, null: false, default: false
    add_column :users, :otp_backup_codes, :text

    add_index :users, :otp_required_for_login
  end
end
