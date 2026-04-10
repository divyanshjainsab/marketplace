class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to profile_path
  end
end
