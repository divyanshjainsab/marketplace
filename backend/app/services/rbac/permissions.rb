require "yaml"

module Rbac
  class Permissions
    CONFIG_PATH = Rails.root.join("config/rbac_permissions.yml").freeze

    def self.codes_for(user:, organization:)
      return [] if user.nil?
      return all_codes if user.respond_to?(:super_admin?) && user.super_admin?

      role = Access.new(user).role_for(organization)
      codes_for_role(role)
    end

    def self.codes_for_role(role)
      role_codes.fetch(role.to_s, []).dup
    end

    def self.all_codes
      role_codes.values.flatten.uniq
    end

    def self.reset!
      @role_codes = nil
    end

    def self.role_codes
      @role_codes ||= load_role_codes
    end

    def self.load_role_codes
      raw = YAML.load_file(CONFIG_PATH) || {}
      roles = raw.fetch("roles", raw.fetch(:roles, {})) || {}

      roles.each_with_object({}) do |(role_name, codes), acc|
        acc[role_name.to_s] = Array(codes).map(&:to_s).reject(&:blank?).uniq
      end
    end
    private_class_method :load_role_codes
  end
end
