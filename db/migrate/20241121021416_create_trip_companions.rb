class CreateTripCompanions < ActiveRecord::Migration[8.0]
  def change
    create_table :trip_companions do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :trip, null: false, foreign_key: true
      t.boolean :accepted, default: false
      t.boolean :declined, default: false

      t.timestamps
    end
  end
end
