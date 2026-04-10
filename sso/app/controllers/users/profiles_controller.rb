module Users
  class ProfilesController < ApplicationController
    before_action :authenticate_user!

    def show
      @user = current_user
      @addresses = current_user.addresses.kept.order(updated_at: :desc).limit(5)
    end

    def update
      @user = current_user
      if @user.update(profile_params)
        redirect_to profile_path, notice: "Profile updated."
      else
        @addresses = current_user.addresses.kept.order(updated_at: :desc).limit(5)
        flash.now[:alert] = @user.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end

    private

    def profile_params
      params.require(:user).permit(:name, :phone_number, :avatar_url)
    end
  end
end

