class CreateTrips < ActiveRecord::Migration[8.0]
  def change
    create_table :trips do |t|
      t.string :name
      t.references :user, null: false, foreign_key: true

      has_many :trip_companions
      has_many :companions, through: :trip_companions, source: :user
    end
  end
end
