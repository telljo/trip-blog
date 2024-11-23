class Trip < ApplicationRecord
  belongs_to :user
  validates :name, presence: true
  validates :body, presence: true
  has_rich_text :body

  broadcasts_refreshes

  has_many :companions, class_name: "User", primary_key: :id, foreign_key: :companion_ids

  def add_companion(user)
    self.companion_ids << user.id
    save
  end
end
