module Auth
  class LoginClaims
    def self.for(user:, session:)
      new(user: user, session: session).for
    end

    def initialize(user:, session:)
      @user = user
      @session = session
    end

    def for
      { roles: user.jwt_roles }
    end

    private

    attr_reader :user, :session
  end
end
