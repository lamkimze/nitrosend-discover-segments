class CreateDiscoveryRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :discovery_runs do |t|
      t.string :status, null: false, default: "complete"
      t.integer :contact_count, null: false, default: 0
      t.integer :segment_count, null: false, default: 0

      t.timestamps
    end
  end
end
