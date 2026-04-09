Rails.application.config.to_prepare do
  Rbac::Registry.reset!
end

