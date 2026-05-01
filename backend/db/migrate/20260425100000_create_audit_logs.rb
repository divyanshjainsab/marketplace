class CreateAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :audit_logs do |t|
      t.bigint :organization_id, null: false
      t.bigint :user_id
      t.string :action, null: false
      t.string :resource_type, null: false
      t.bigint :resource_id, null: false
      t.jsonb :changes, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.index :organization_id
      t.index :user_id
      t.index :action
      t.index %i[resource_type resource_id]
      t.index %i[organization_id action created_at]
      t.index %i[organization_id resource_type resource_id]
    end

    add_foreign_key :audit_logs, :organizations
    add_foreign_key :audit_logs, :users
  end
end
