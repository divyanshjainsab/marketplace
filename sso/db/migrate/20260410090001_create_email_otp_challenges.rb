class CreateEmailOtpChallenges < ActiveRecord::Migration[7.1]
  def change
    create_table :email_otp_challenges do |t|
      t.references :user, null: false, foreign_key: true
      t.string :purpose, null: false
      t.string :code_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :consumed_at
      t.integer :attempts, null: false, default: 0
      t.integer :sent_count, null: false, default: 1
      t.datetime :last_sent_at, null: false

      t.timestamps
    end

    add_index :email_otp_challenges, [:user_id, :purpose, :consumed_at], name: "idx_email_otp_challenges_active_lookup"
    add_index :email_otp_challenges, :expires_at
  end
end
