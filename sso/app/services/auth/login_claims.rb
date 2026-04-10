module Auth
  class LoginClaims
    Denied = Class.new(StandardError)

    def self.for(user:, session:)
      new(user: user, session: session).for
    end

    def initialize(user:, session:)
      @user = user
      @session = session
    end

    def for
      org_slug = session[:login_org_slug].to_s
      if org_slug.present?
        result = BackendClaims.fetch(user: user, org_slug: org_slug)
        raise Denied, "You do not have admin access for this organization." unless result.allowed?

        { roles: result.roles.presence || ["user", "admin"], org_id: result.org_id }
      else
        { roles: user.jwt_roles, org_id: nil }
      end
    end

    private

    attr_reader :user, :session
  end
end

