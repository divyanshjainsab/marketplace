class ApplicationController < ActionController::API
  include PaperTrail::Rails::Controller
  include Pundit::Authorization

  before_action :set_current_tenant
  before_action :set_paper_trail_whodunnit
  before_action :set_paper_trail_controller_info
  after_action :reset_current_tenant

  private

  def set_current_tenant
    ActsAsTenant.current_tenant = Current.marketplace
  end

  def reset_current_tenant
    ActsAsTenant.current_tenant = nil
  end

  def pundit_user
    Current.user
  end

  def user_for_paper_trail
    Current.user&.external_id
  end

  def set_paper_trail_controller_info
    PaperTrail.request.controller_info = {
      marketplace_id: Current.marketplace&.id
    }
  end
end
