# frozen_string_literal: true

module TenantCache
  class MissingTenantError < StandardError; end

  TENANT_PREFIX = "tenant"
  VERSION_PREFIX = "v"

  def self.fetch(namespace:, key:, organization: nil, organization_id: nil, version: nil, **options, &block)
    org_id = resolve_organization_id(organization: organization, organization_id: organization_id)
    cache_key = build_key(organization_id: org_id, namespace: namespace, key: key, version: version)
    Rails.cache.fetch(cache_key, **options, &block)
  end

  def self.read(namespace:, key:, organization: nil, organization_id: nil, version: nil)
    org_id = resolve_organization_id(organization: organization, organization_id: organization_id)
    Rails.cache.read(build_key(organization_id: org_id, namespace: namespace, key: key, version: version))
  end

  def self.write(namespace:, key:, value:, organization: nil, organization_id: nil, version: nil, **options)
    org_id = resolve_organization_id(organization: organization, organization_id: organization_id)
    Rails.cache.write(build_key(organization_id: org_id, namespace: namespace, key: key, version: version), value, **options)
  end

  def self.delete(namespace:, key:, organization: nil, organization_id: nil, version: nil)
    org_id = resolve_organization_id(organization: organization, organization_id: organization_id)
    Rails.cache.delete(build_key(organization_id: org_id, namespace: namespace, key: key, version: version))
  end

  def self.increment(namespace:, key:, amount: 1, organization: nil, organization_id: nil, version: nil, **options)
    org_id = resolve_organization_id(organization: organization, organization_id: organization_id)
    cache_key = build_key(organization_id: org_id, namespace: namespace, key: key, version: version)

    Rails.cache.increment(cache_key, amount, **options)
  rescue NotImplementedError, NoMethodError
    current = Rails.cache.read(cache_key).to_i
    next_value = current + amount.to_i
    Rails.cache.write(cache_key, next_value, expires_in: options[:expires_in])
    next_value
  end

  def self.namespace_version(organization_id:, namespace:)
    org_id = normalize_id(organization_id)
    ns = normalize_segment(namespace, label: "namespace")
    Rails.cache.fetch(version_key(organization_id: org_id, namespace: ns)) { 1 }.to_i
  end

  def self.bump_namespace_version!(organization_id:, namespace:)
    org_id = normalize_id(organization_id)
    ns = normalize_segment(namespace, label: "namespace")

    Rails.cache.increment(version_key(organization_id: org_id, namespace: ns), 1, initial: 1).to_i
  rescue StandardError
    next_version = namespace_version(organization_id: org_id, namespace: ns) + 1
    Rails.cache.write(version_key(organization_id: org_id, namespace: ns), next_version)
    next_version
  end

  def self.build_key(organization_id:, namespace:, key:, version: nil)
    org_id = normalize_id(organization_id)
    ns = normalize_segment(namespace, label: "namespace")
    k = normalize_segment(key, label: "key")
    v = (version || namespace_version(organization_id: org_id, namespace: ns)).to_i

    "#{TENANT_PREFIX}:#{org_id}:#{VERSION_PREFIX}#{v}:#{ns}:#{k}"
  end

  def self.version_key(organization_id:, namespace:)
    org_id = normalize_id(organization_id)
    ns = normalize_segment(namespace, label: "namespace")
    "#{TENANT_PREFIX}:#{org_id}:#{VERSION_PREFIX}:#{ns}"
  end

  def self.resolve_organization_id(organization:, organization_id:)
    return normalize_id(organization_id) if organization_id.present?

    if organization.respond_to?(:id)
      return normalize_id(organization.id)
    end

    if defined?(Current) && Current.respond_to?(:organization) && Current.organization&.id.present?
      return normalize_id(Current.organization.id)
    end

    raise MissingTenantError, "Missing organization_id for tenant-scoped cache access"
  end

  def self.normalize_id(value)
    id = value.to_i
    raise MissingTenantError, "Missing organization_id for tenant-scoped cache access" if id <= 0

    id
  end

  def self.normalize_segment(value, label:)
    segment = value.to_s
    raise ArgumentError, "#{label} is required" if segment.blank?

    segment.gsub(" ", "_")
  end

  private_class_method :resolve_organization_id, :normalize_id, :normalize_segment
end
