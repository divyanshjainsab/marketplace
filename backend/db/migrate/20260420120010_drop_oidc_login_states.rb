class DropOidcLoginStates < ActiveRecord::Migration[7.1]
  def change
    drop_table :oidc_login_states, if_exists: true
  end
end

