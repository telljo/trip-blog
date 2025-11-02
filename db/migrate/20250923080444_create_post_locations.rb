class CreatePostLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :post_locations do |t|
      t.float :latitude
      t.float :longitude
      t.string :street
      t.string :city
      t.string :state
      t.string :country
      t.integer :travel_type, default: nil
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end
  end
end
