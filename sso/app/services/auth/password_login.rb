module Auth
  class PasswordLogin
    Result = Struct.new(:status, :user, :message, :error_code, keyword_init: true) do
      def authenticated?
        status == :authenticated
      end

      def otp_required?
        status == :otp_required
      end

      def email_verification_required?
        status == :email_verification_required
      end

      def locked?
        status == :locked
      end
    end

    def self.call(email:, password:)
      new(email: email, password: password).call
    end

    def initialize(email:, password:)
      @email = email.to_s.strip.downcase
      @password = password.to_s
    end

    def call
      return invalid_result if email.blank? || password.blank?

      user = User.find_for_authentication(email: email)
      return invalid_result if user.nil?
      return locked_result(user) if user.access_locked?

      authenticated = user.valid_password?(password)
      register_failure!(user) unless authenticated
      return locked_result(user) if user.access_locked?
      return invalid_result unless authenticated

      user.reset_failed_attempts! if user.respond_to?(:reset_failed_attempts!) && user.failed_attempts.to_i.positive?

      Result.new(
        status: authentication_status_for(user),
        user: user
      )
    end

    private

    attr_reader :email, :password

    def invalid_result
      Result.new(
        status: :invalid,
        message: "The email or password you entered is incorrect.",
        error_code: :invalid_credentials
      )
    end

    def locked_result(user)
      Result.new(
        status: :locked,
        user: user,
        message: "Your account is temporarily locked. Try again later.",
        error_code: :locked
      )
    end

    def authentication_status_for(user)
      return :email_verification_required unless user.email_verified?
      return :otp_required if user.otp_required_for_login?

      :authenticated
    end

    def register_failure!(user)
      return unless user.respond_to?(:increment_failed_attempts)

      user.increment_failed_attempts
      user.lock_access! if user.failed_attempts >= Devise.maximum_attempts && user.respond_to?(:lock_access!)
    end
  end
end
