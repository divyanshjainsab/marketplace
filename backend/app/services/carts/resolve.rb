module Carts
  class Resolve
    def self.call(marketplace:, user:, session_id:)
      new(marketplace: marketplace, user: user, session_id: session_id).call
    end

    def initialize(marketplace:, user:, session_id:)
      @marketplace = marketplace
      @user = user
      @session_id = session_id.to_s.strip
    end

    def call
      raise ActiveRecord::RecordNotFound, "Marketplace context is required" if @marketplace.nil?

      session_id = normalize_session_id(@session_id)

      if @user.present?
        resolve_for_user(session_id)
      else
        resolve_for_guest(session_id)
      end
    end

    private

    def normalize_session_id(value)
      return SecureRandom.uuid if value.blank?

      value
    end

    def resolve_for_guest(session_id)
      Cart.kept.find_or_create_by!(marketplace_id: @marketplace.id, session_id: session_id) do |cart|
        cart.user = nil
      end
    end

    def resolve_for_user(session_id)
      user_cart = Cart.kept.find_by(marketplace_id: @marketplace.id, user_id: @user.id)
      session_cart = Cart.kept.find_by(marketplace_id: @marketplace.id, session_id: session_id)

      if user_cart.present?
        if session_cart.present? && session_cart.id != user_cart.id
          merge_items!(from: session_cart, into: user_cart)
          session_cart.discard
        end

        user_cart.update!(session_id: session_id) if user_cart.session_id != session_id
        return user_cart
      end

      if session_cart.present?
        session_cart.update!(user_id: @user.id)
        return session_cart
      end

      Cart.create!(marketplace_id: @marketplace.id, user_id: @user.id, session_id: session_id)
    end

    def merge_items!(from:, into:)
      from.cart_items.kept.each do |item|
        destination = into.cart_items.kept.find_or_initialize_by(variant_id: item.variant_id)
        destination.quantity = (destination.quantity || 0) + item.quantity
        destination.save!
        item.discard
      end
    end
  end
end

