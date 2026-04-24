module Api
  class LandingComponentsController < BaseController
    before_action :require_user!

    def show
      component = LandingComponent.kept.find(params[:id])
      render json: SiteEditor::ComponentRenderer.new(component, marketplace: current_marketplace).render
    end
  end
end

