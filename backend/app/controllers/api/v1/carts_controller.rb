module Api
  module V1
    class CartsController < BaseController
      def show
        authorize Cart

        cart = Carts::Resolve.call(
          marketplace: Current.marketplace,
          user: Current.user,
          session_id: params[:session_id]
        )

        render json: { data: CartSerializer.one(cart) }
      end
    end
  end
end

