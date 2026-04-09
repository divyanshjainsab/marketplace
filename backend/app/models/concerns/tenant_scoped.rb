module TenantScoped
  extend ActiveSupport::Concern

  included do
    acts_as_tenant :marketplace
  end
end
