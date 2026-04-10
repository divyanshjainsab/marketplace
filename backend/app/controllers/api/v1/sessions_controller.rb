module Api
  module V1
    class SessionsController < BaseController
      def show
        organization = nil
        if Current.org_id.present?
          organization = Rails.cache.fetch("org:by_id:#{Current.org_id}", expires_in: 60) do
            Organization.kept.find_by(id: Current.org_id)
          end
        end

        render json: {
          data: {
            user: Current.user ? UserSerializer.one(Current.user) : nil,
            marketplace: Current.marketplace ? MarketplaceSerializer.one(Current.marketplace) : nil,
            organization: organization ? OrganizationSerializer.one(organization) : nil
          }
        }
      end
    end
  end
end
