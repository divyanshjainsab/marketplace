module Auth
  class OtpChallenge
    SESSION_KEY = :sso_otp_challenge
    TTL = 5.minutes
    MAX_ATTEMPTS = 5

    Challenge = Struct.new(:user_id, :return_to, :expires_at, :attempts, keyword_init: true) do
      def expired?
        expires_at <= Time.current
      end
    end

    # `return_to` is optional; the OIDC flow does not require app-level return targets.
    def self.start(session:, user:, return_to: nil)
      new(session).start(user: user, return_to: return_to)
    end

    def self.fetch(session:)
      new(session).fetch
    end

    def self.active?(session:)
      challenge = fetch(session: session)
      challenge.present? && !challenge.expired?
    end

    def self.clear(session:)
      new(session).clear
    end

    def self.touch(session:)
      new(session).touch
    end

    def self.increment_attempts(session:)
      new(session).increment_attempts
    end

    def initialize(session)
      @session = session
    end

    def start(user:, return_to: nil)
      payload = {
        "user_id" => user.id,
        "return_to" => return_to,
        "expires_at" => TTL.from_now.to_i,
        "attempts" => 0
      }

      session[SESSION_KEY] = payload
      build(payload)
    end

    def fetch
      payload = session[SESSION_KEY]
      return nil unless payload.is_a?(Hash)

      build(payload)
    end

    def clear
      session.delete(SESSION_KEY)
    end

    def touch
      challenge = fetch
      return nil if challenge.nil?

      session[SESSION_KEY]["expires_at"] = TTL.from_now.to_i
      fetch
    end

    def increment_attempts
      challenge = fetch
      return nil if challenge.nil?

      session[SESSION_KEY]["attempts"] = challenge.attempts + 1
      fetch
    end

    private

    attr_reader :session

    def build(payload)
      Challenge.new(
        user_id: payload["user_id"].to_i,
        return_to: payload["return_to"].presence,
        expires_at: Time.at(payload["expires_at"].to_i),
        attempts: payload["attempts"].to_i
      )
    end
  end
end
