require "rotp"

user = User.find_or_initialize_by(email: "owner@example.com")
user.name = "Demo Owner"
user.external_id = "11111111-1111-1111-1111-111111111111"
user.password = "Password123"
user.password_confirmation = "Password123"
user.otp_required_for_login = true
user.otp_secret = "JBSWY3DPEHPK3PXP"
user.save!

totp = ROTP::TOTP.new(user.otp_secret, issuer: "Marketplace SSO")

puts "Seeded SSO user: owner@example.com"
puts "Password: Password123"
puts "OTP secret: #{user.otp_secret}"
puts "Current OTP: #{totp.now}"
