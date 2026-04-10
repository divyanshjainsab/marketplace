module Auth
  class SessionCompletion
    Result = Struct.new(:token_pair, :redirect_url, keyword_init: true)

    def self.call(user:, request:, redirect_target:, fallback:, claims: {})
      new(user: user, request: request, redirect_target: redirect_target, fallback: fallback, claims: claims).call
    end

    def initialize(user:, request:, redirect_target:, fallback:, claims:)
      @user = user
      @request = request
      @redirect_target = redirect_target
      @fallback = fallback
      @claims = claims || {}
    end

    def call
      token_pair = Sso::RefreshTokens.issue(user: user, request: request, claims: claims)

      Result.new(
        token_pair: token_pair,
        redirect_url: Auth::ReturnTo.build_redirect(
          target: redirect_target,
          token_pair: token_pair,
          fallback: fallback
        )
      )
    end

    private

    attr_reader :user, :request, :redirect_target, :fallback, :claims
  end
end
