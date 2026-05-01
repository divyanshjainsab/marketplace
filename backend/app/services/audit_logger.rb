# frozen_string_literal: true

module AuditLogger
  class MissingContextError < StandardError; end
  class TenantMismatchError < StandardError; end

  def self.log(user:, org:, action:, resource:, changes: nil, metadata: nil)
    organization = org
    raise MissingContextError, "org is required" if organization.nil?

    normalized_action = action.to_s.strip
    raise ArgumentError, "action is required" if normalized_action.blank?

    raise ArgumentError, "resource is required" if resource.nil?
    resource_type = resource.class.name
    resource_id = resource.respond_to?(:id) ? resource.id : nil
    raise ArgumentError, "resource must be persisted" if resource_id.blank?

    enforce_resource_tenant!(organization: organization, resource: resource)

    base_metadata = default_metadata
    normalized_metadata = normalize_json((base_metadata || {}).merge(normalize_hash(metadata))) if metadata.present?
    normalized_metadata ||= normalize_json(base_metadata || {})

    normalized_changes = normalize_json(normalize_hash(changes))

    record = AuditLog.create!(
      organization_id: organization.id,
      user_id: user&.id,
      action: normalized_action,
      resource_type: resource_type,
      resource_id: resource_id,
      changes: normalized_changes,
      metadata: normalized_metadata
    )

    ActiveSupport::Notifications.instrument(
      "audit.logged",
      audit_log_id: record.id,
      organization_id: organization.id,
      user_id: user&.id,
      action: normalized_action,
      resource_type: resource_type,
      resource_id: resource_id
    )

    record
  end

  def self.default_metadata
    return {} unless defined?(Current)

    {
      request_id: Current.respond_to?(:request_id) ? Current.request_id : nil,
      request_host: Current.request_host,
      remote_ip: Current.respond_to?(:remote_ip) ? Current.remote_ip : nil,
      user_agent: Current.respond_to?(:user_agent) ? Current.user_agent : nil,
      session_org_id: Current.session_org_id,
      session_roles: Current.session_roles,
      marketplace_id: Current.marketplace&.id
    }.compact
  end
  private_class_method :default_metadata

  def self.enforce_resource_tenant!(organization:, resource:)
    derived_org_id = resource_organization_id(resource)
    return if derived_org_id.nil?
    return if derived_org_id.to_i == organization.id.to_i

    raise TenantMismatchError, "Audit log org mismatch for #{resource.class.name}##{resource.id}: #{derived_org_id} != #{organization.id}"
  end
  private_class_method :enforce_resource_tenant!

  def self.resource_organization_id(resource)
    return resource.id if resource.is_a?(Organization)

    if resource.respond_to?(:organization_id) && resource.organization_id.present?
      return resource.organization_id
    end

    if resource.respond_to?(:organization) && resource.organization&.id.present?
      return resource.organization.id
    end

    if resource.respond_to?(:marketplace) && resource.marketplace&.organization_id.present?
      return resource.marketplace.organization_id
    end

    if resource.respond_to?(:market_place) && resource.market_place&.organization_id.present?
      return resource.market_place.organization_id
    end

    nil
  end
  private_class_method :resource_organization_id

  def self.normalize_json(value)
    case value
    when Hash
      value.each_with_object({}) do |(k, v), out|
        out[k.to_s] = normalize_json(v)
      end
    when Array
      value.map { |v| normalize_json(v) }
    when Time
      value.iso8601
    when DateTime
      value.iso8601
    when Date
      value.iso8601
    when ActiveSupport::TimeWithZone
      value.iso8601
    when BigDecimal
      value.to_s("F")
    else
      value
    end
  end
  private_class_method :normalize_json

  def self.normalize_hash(value)
    case value
    when nil
      {}
    when ActionController::Parameters
      value.to_unsafe_h
    when Hash
      value
    else
      value.respond_to?(:to_h) ? value.to_h : {}
    end
  end
  private_class_method :normalize_hash
end
