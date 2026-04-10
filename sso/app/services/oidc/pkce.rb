require "base64"
require "digest"

module Oidc
  class Pkce
    def self.code_challenge(verifier)
      digest = Digest::SHA256.digest(verifier.to_s)
      Base64.urlsafe_encode64(digest, padding: false)
    end

    def self.verify!(verifier:, expected_challenge:, method:)
      raise Errors::InvalidRequest, "pkce_required" if expected_challenge.to_s.blank?
      raise Errors::InvalidRequest, "unsupported_challenge_method" unless method.to_s == "S256"

      actual = code_challenge(verifier)
      unless ActiveSupport::SecurityUtils.secure_compare(actual, expected_challenge.to_s)
        raise Errors::InvalidGrant, "invalid_code_verifier"
      end

      true
    end
  end
end

