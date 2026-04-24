module Api
  module V1
    class CartItemsController < BaseController
      def create
        authorize Cart

        cart = resolve_cart
        Carts::AddItem.call(cart: cart, variant_id: variant_id_param, quantity: quantity_param)

        render json: { data: CartSerializer.one(cart.reload) }
      end

      def update
        authorize Cart

        cart = resolve_cart
        Carts::SetItemQuantity.call(cart: cart, variant_id: variant_id_param, quantity: quantity_param)

        render json: { data: CartSerializer.one(cart.reload) }
      end

      def destroy
        authorize Cart

        cart = resolve_cart
        Carts::RemoveItem.call(cart: cart, variant_id: variant_id_param)

        render json: { data: CartSerializer.one(cart.reload) }
      end

      private

      def resolve_cart
        Carts::Resolve.call(
          marketplace: Current.marketplace,
          user: Current.user,
          session_id: params[:session_id]
        )
      end

      def variant_id_param
        (params[:variant_id].presence || params[:id]).to_i
      end

      def quantity_param
        raw = params[:quantity]
        raw.present? ? raw.to_i : 1
      end
    end
  end
end

