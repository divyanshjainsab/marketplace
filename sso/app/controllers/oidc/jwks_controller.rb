module Oidc
  class JwksController < ApplicationController
    skip_before_action :verify_authenticity_token

    def show
      render json: SigningKey.current.jwks_payload
    end
  end
end

