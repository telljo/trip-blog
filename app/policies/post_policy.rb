class PostPolicy < ApplicationPolicy
  def destroy?
    update?
  end

  def new?
    update?
  end

  def create?
    update?
  end

  def edit?
    update?
  end

  def update?
    user == record&.trip&.user || record&.trip&.users&.include?(user)
  end
end
