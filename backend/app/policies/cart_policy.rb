class CartPolicy < ApplicationPolicy
  def show?
    true
  end

  def create?
    true
  end

  def update?
    true
  end

  def destroy?
    true
  end

  class Scope < Scope
    def resolve
      return scope.none if Current.marketplace.nil?

      scope.kept.where(marketplace_id: Current.marketplace.id)
    end
  end
end

