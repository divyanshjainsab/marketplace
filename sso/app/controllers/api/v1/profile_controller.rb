module Api
  module V1
    class ProfileController < BaseController
      def show
        render json: { data: serialize_user(current_api_user) }
      end

      def update
        user = current_api_user
        if user.update(profile_params)
          render json: { data: serialize_user(user) }
        else
          render json: { error: "validation_failed", details: user.errors.to_hash(true) }, status: :unprocessable_entity
        end
      end

      private

      def profile_params
        params.require(:profile).permit(:name, :phone_number, :avatar_url)
      end

      def serialize_user(user)
        {
          external_id: user.external_id,
          email: user.email,
          name: user.name,
          phone_number: user.phone_number,
          avatar_url: user.avatar_url
        }
      end
    end
  end
end

