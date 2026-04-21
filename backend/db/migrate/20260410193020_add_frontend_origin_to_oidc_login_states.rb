class AddFrontendOriginToOidcLoginStates < ActiveRecord::Migration[7.1]
  def change
    add_column :oidc_login_states, :frontend_origin, :string
    add_index :oidc_login_states, :frontend_origin
  end
end

