# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :organization
  belongs_to :user, optional: true

  validates :organization_id, presence: true
  validates :action, presence: true
  validates :resource_type, presence: true
  validates :resource_id, presence: true

  before_update :raise_immutable
  before_destroy :raise_immutable

  def readonly?
    persisted?
  end

  def changes
    self[:changes]
  end

  private

  def raise_immutable
    raise ActiveRecord::ReadOnlyRecord, "Audit logs are immutable"
  end
end

