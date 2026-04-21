SEED_PASSWORD = "Password123!"

def seed_user!(external_id:, email:, name:, password: SEED_PASSWORD, super_admin: false)
  user = User.find_or_initialize_by(external_id: external_id)
  user.email = email
  user.name = name
  user.password = password
  user.password_confirmation = password
  user.email_verified = true
  user.otp_required_for_login = false
  user.otp_secret = nil
  user.otp_backup_codes = []
  user.super_admin = super_admin
  user.save!
  user
end

seed_user!(
  external_id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  email: "superadmin@test.com",
  name: "Super Admin",
  super_admin: true
)

seed_user!(
  external_id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
  email: "adminA@test.com",
  name: "Org Admin A"
)

seed_user!(
  external_id: "cccccccc-cccc-cccc-cccc-cccccccccccc",
  email: "adminB@test.com",
  name: "Org Admin B"
)

seed_user!(
  external_id: "dddddddd-dddd-dddd-dddd-dddddddddddd",
  email: "user@test.com",
  name: "Normal User"
)

puts "Seeded SSO users:"
puts "- superadmin@test.com (Super Admin)"
puts "- adminA@test.com (Org Admin A)"
puts "- adminB@test.com (Org Admin B)"
puts "- user@test.com (Normal User)"
puts "Password for all seeded users: #{SEED_PASSWORD}"
