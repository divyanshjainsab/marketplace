class MakeTwoFactorOptionalByDefault < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :otp_required_for_login, from: true, to: false
  end
end
