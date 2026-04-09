class EnforceTwoFactorOnUsers < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :otp_required_for_login, from: false, to: true
  end
end

