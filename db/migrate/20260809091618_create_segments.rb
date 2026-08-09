class CreateSegments < ActiveRecord::Migration[8.1]
  def change
    create_table :segments do |t|
      t.references :discovery_run, null: false, foreign_key: true
      t.string :name, null: false
      t.string :status, null: false, default: "proposed"
      t.string :strength, null: false, default: "moderate"
      t.integer :contact_count, null: false, default: 0
      t.string :destination
      t.string :trip_style
      t.json :reasons, default: []
      t.string :campaign_subject
      t.text :campaign_angle
      t.text :campaign_why
      t.string :pattern_key
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :segments, :status
    add_index :segments, :pattern_key
  end
end
