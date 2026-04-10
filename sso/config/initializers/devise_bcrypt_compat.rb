# frozen_string_literal: true

require "devise/encryptor"

module Devise
  unless respond_to?(:bcrypt)
    def self.bcrypt(klass, password)
      Encryptor.digest(klass, password)
    end
  end
end
