class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("SSO_MAILER_FROM", "no-reply@marketplace.local")
  layout "mailer"
end
