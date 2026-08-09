class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :primary_destination
      t.string :trip_style
      t.string :spend_band
      t.integer :engagement_score, default: 0, null: false
      t.integer :opens_30d, default: 0, null: false
      t.integer :clicks_30d, default: 0, null: false
      t.datetime :last_opened_at
      t.integer :booked_trips, default: 0, null: false
      t.json :tags, default: []
      t.json :browse_destinations, default: []
      t.text :notes

      t.timestamps
    end

    add_index :contacts, :email, unique: true
    add_index :contacts, :primary_destination
    add_index :contacts, :trip_style
  end
end
