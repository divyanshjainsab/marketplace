require "yaml"

module Rbac
  class Registry
    CONFIG_PATH = Rails.root.join("config/rbac.yml").freeze

    def self.rank_for(role)
      return unknown_rank if role.nil?

      role_ranks.fetch(role.to_s, unknown_rank)
    end

    def self.known_role?(role)
      role_ranks.key?(role.to_s)
    end

    def self.role_names
      role_ranks.keys
    end

    def self.reset!
      @role_ranks = nil
    end

    def self.role_ranks
      @role_ranks ||= load_role_ranks
    end

    def self.load_role_ranks
      raw = YAML.load_file(CONFIG_PATH) || {}
      roles = raw.fetch("roles", raw.fetch(:roles, {})) || {}

      roles.each_with_object({}) do |(k, v), acc|
        acc[k.to_s] = Integer(v)
      rescue ArgumentError, TypeError
        acc[k.to_s] = 0
      end
    end
    private_class_method :load_role_ranks

    def self.unknown_rank
      -1_000_000
    end
    private_class_method :unknown_rank
  end
end

