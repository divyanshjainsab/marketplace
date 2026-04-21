class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("SSO_MAILER_FROM")
  layout "mailer"
end
