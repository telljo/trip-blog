class TripPolicy < ApplicationPolicy
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
    user == record.user || record&.users&.include?(user)
  end
end
