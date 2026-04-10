require "digest"

module Auth
  class EmailOtpService
    PURPOSE_EMAIL_VERIFICATION = "email_verification".freeze
    PURPOSE_TWO_FACTOR_RECOVERY = "two_factor_recovery".freeze
    OTP_TTL = 5.minutes
    MAX_ATTEMPTS = 5

    IssueResult = Struct.new(:challenge, :code, keyword_init: true)
    VerifyResult = Struct.new(:ok?, :reason, :challenge, keyword_init: true)

    def self.issue(user:, purpose:)
      new.issue(user: user, purpose: purpose)
    end

    def self.verify(user:, purpose:, code:)
      new.verify(user: user, purpose: purpose, code: code)
    end

    def self.latest_active_for(user:, purpose:)
      EmailOtpChallenge.active.where(user: user, purpose: purpose).recent_first.first
    end

    def issue(user:, purpose:)
      code = format("%06d", SecureRandom.random_number(1_000_000))

      EmailOtpChallenge.transaction do
        EmailOtpChallenge.where(user: user, purpose: purpose, consumed_at: nil).update_all(consumed_at: Time.current)
        challenge = EmailOtpChallenge.create!(
          user: user,
          purpose: purpose,
          code_digest: digest(code),
          expires_at: OTP_TTL.from_now,
          last_sent_at: Time.current
        )

        AuthMailer.with(user: user, code: code, purpose: purpose, expires_in_minutes: (OTP_TTL / 60).to_i).email_otp.deliver_later

        IssueResult.new(challenge: challenge, code: code)
      end
    end

    def verify(user:, purpose:, code:)
      challenge = self.class.latest_active_for(user: user, purpose: purpose)
      return VerifyResult.new(ok?: false, reason: :missing, challenge: nil) if challenge.nil?
      return VerifyResult.new(ok?: false, reason: :expired, challenge: challenge) if challenge.expires_at <= Time.current

      if challenge.attempts >= MAX_ATTEMPTS
        challenge.update!(consumed_at: Time.current)
        return VerifyResult.new(ok?: false, reason: :too_many_attempts, challenge: challenge)
      end

      normalized = code.to_s.gsub(/\D/, "")
      unless secure_match?(challenge.code_digest, digest(normalized))
        challenge.increment!(:attempts)
        return VerifyResult.new(ok?: false, reason: :invalid, challenge: challenge)
      end

      challenge.update!(consumed_at: Time.current)
      VerifyResult.new(ok?: true, reason: :ok, challenge: challenge)
    end

    private

    def digest(code)
      Digest::SHA256.hexdigest(code.to_s)
    end

    def secure_match?(left, right)
      ActiveSupport::SecurityUtils.secure_compare(left, right)
    end
  end
end
