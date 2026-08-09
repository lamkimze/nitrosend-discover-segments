class CreateInsights < ActiveRecord::Migration[8.1]
  def change
    create_table :insights do |t|
      t.references :discovery_run, null: false, foreign_key: true
      t.text :body, null: false
      t.string :kind, null: false, default: "trend"
      t.integer :position, default: 0, null: false

      t.timestamps
    end
  end
end
