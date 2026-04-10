module Users
  class AddressesController < ApplicationController
    before_action :authenticate_user!
    before_action :load_address!, only: %i[edit update destroy]

    def index
      @addresses = current_user.addresses.kept.order(updated_at: :desc)
    end

    def new
      @address = current_user.addresses.new(address_type: "home")
    end

    def create
      @address = current_user.addresses.new(address_params)
      if @address.save
        redirect_to addresses_path, notice: "Address added."
      else
        flash.now[:alert] = @address.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotUnique
      @address.errors.add(:base, "That address already exists.")
      flash.now[:alert] = @address.errors.full_messages.to_sentence
      render :new, status: :conflict
    end

    def edit
    end

    def update
      if @address.update(address_params)
        redirect_to addresses_path, notice: "Address updated."
      else
        flash.now[:alert] = @address.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @address.discard!
      redirect_to addresses_path, notice: "Address removed."
    end

    private

    def load_address!
      @address = current_user.addresses.kept.find(params[:id])
    end

    def address_params
      params.require(:address).permit(:address_type, :line1, :line2, :city, :state, :country, :zip_code)
    end
  end
end

