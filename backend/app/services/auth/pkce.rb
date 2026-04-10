require "base64"
require "digest"

module Auth
  class Pkce
    def self.code_challenge(verifier)
      digest = Digest::SHA256.digest(verifier.to_s)
      Base64.urlsafe_encode64(digest, padding: false)
    end
  end
end

