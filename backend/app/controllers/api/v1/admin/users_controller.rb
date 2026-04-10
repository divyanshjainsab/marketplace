module Api
  module V1
    module Admin
      class UsersController < BaseController
        def index
          page = paginate(User.kept.order(created_at: :desc))
          render_collection(page, serializer: UserSerializer)
        end

        def show
          user = User.kept.find(params[:id])
          render_resource(user, serializer: UserSerializer)
        end
      end
    end
  end
end

