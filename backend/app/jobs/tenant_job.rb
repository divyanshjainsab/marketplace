# frozen_string_literal: true

class TenantJob < ApplicationJob
  before_enqueue :ensure_organization_id!
  around_perform :with_tenant_context

  private

  def ensure_organization_id!
    org_id = organization_id_from_arguments
    raise ArgumentError, "organization_id is required for tenant jobs" if org_id <= 0
  end

  def with_tenant_context
    org_id = organization_id_from_arguments
    context = context_from_arguments

    organization = Organization.kept.find(org_id)

    previous = Current.attributes if defined?(Current)

    Current.organization = organization
    Current.org_id = organization.id
    Current.request_host = context[:request_host] if context[:request_host].present?

    if context[:marketplace_id].present?
      marketplace = Marketplace.kept.find_by(id: context[:marketplace_id], organization_id: organization.id)
      Current.marketplace = marketplace
      ActsAsTenant.current_tenant = marketplace if marketplace.present?
    end

    Rails.logger.info(
      {
        event: "tenant_job.start",
        job: self.class.name,
        job_id: job_id,
        organization_id: organization.id,
        marketplace_id: Current.marketplace&.id
      }.to_json
    )

    yield
  ensure
    Rails.logger.info(
      {
        event: "tenant_job.finish",
        job: self.class.name,
        job_id: job_id,
        organization_id: Current.organization&.id,
        marketplace_id: Current.marketplace&.id
      }.to_json
    )

    ActsAsTenant.current_tenant = nil
    if defined?(Current)
      Current.reset
      previous&.each do |name, value|
        Current.public_send("#{name}=", value)
      end
    end
  end

  def organization_id_from_arguments
    arguments.first.to_i
  end

  def context_from_arguments
    raw = arguments.last.is_a?(Hash) ? arguments.last : {}
    {
      request_host: raw[:request_host] || raw["request_host"],
      marketplace_id: raw[:marketplace_id] || raw["marketplace_id"]
    }.compact
  end
end

