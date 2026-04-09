module Api
  module V1
    class SessionsController < BaseController
      def show
      render json: {
        data: {
          user: Current.user ? UserSerializer.one(Current.user) : nil,
          marketplace: Current.marketplace ? MarketplaceSerializer.one(Current.marketplace) : nil
        }
      }
      end
    end
  end
end
