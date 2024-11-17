class Trip < ApplicationRecord
  belongs_to :user
  validates :name, presence: true
  validates :body, presence: true
  has_rich_text :body

  broadcasts_refreshes
end
