class CreateTripFollower < ActiveRecord::Migration[8.0]
  def change
    create_table :trip_followers do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
