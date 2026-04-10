module Api
  module V1
    class AddressesController < BaseController
      def index
        addresses = current_api_user.addresses.kept.order(updated_at: :desc)
        render json: { data: addresses.map { |a| serialize_address(a) } }
      end

      def create
        address = current_api_user.addresses.new(address_params)
        if address.save
          render json: { data: serialize_address(address) }, status: :created
        else
          render json: { error: "validation_failed", details: address.errors.to_hash(true) }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotUnique
        render json: { error: "duplicate_address" }, status: :conflict
      end

      def update
        address = current_api_user.addresses.kept.find(params[:id])
        if address.update(address_params)
          render json: { data: serialize_address(address) }
        else
          render json: { error: "validation_failed", details: address.errors.to_hash(true) }, status: :unprocessable_entity
        end
      end

      def destroy
        address = current_api_user.addresses.kept.find(params[:id])
        address.discard!
        render json: { ok: true }
      end

      private

      def address_params
        params.require(:address).permit(:address_type, :line1, :line2, :city, :state, :country, :zip_code)
      end

      def serialize_address(address)
        {
          id: address.id,
          address_type: address.address_type,
          line1: address.line1,
          line2: address.line2,
          city: address.city,
          state: address.state,
          country: address.country,
          zip_code: address.zip_code,
          updated_at: address.updated_at.iso8601
        }
      end
    end
  end
end

