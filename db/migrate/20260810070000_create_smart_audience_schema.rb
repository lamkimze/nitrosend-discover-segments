class CreateSmartAudienceSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.string :email, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :country
      t.string :source, default: "import"
      t.timestamps
    end
    add_index :contacts, :email, unique: true

    create_table :events do |t|
      t.references :contact, null: false, foreign_key: true
      t.string :event_type, null: false
      t.json :metadata, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :events, [ :contact_id, :event_type ]
    add_index :events, :occurred_at

    create_table :segments do |t|
      t.string :name, null: false
      t.text :description
      t.string :source, null: false, default: "ai"
      t.decimal :confidence_score, precision: 5, scale: 4, default: 0
      t.string :status, null: false, default: "active"
      t.json :evidence, default: []
      t.integer :contact_count, null: false, default: 0
      t.string :slug
      t.timestamps
    end
    add_index :segments, :slug, unique: true
    add_index :segments, :status
    add_index :segments, :source

    create_table :segment_memberships do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :segment, null: false, foreign_key: true
      t.decimal :score, precision: 5, scale: 4
      t.text :reason
      t.timestamps
    end
    add_index :segment_memberships, [ :segment_id, :contact_id ], unique: true

    create_table :ai_analysis_runs do |t|
      t.string :status, null: false, default: "pending"
      t.string :model, default: "demo"
      t.integer :contact_count, default: 0, null: false
      t.integer :segments_found, default: 0, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.text :error_message
      t.json :summary, default: {}
      t.timestamps
    end
    add_index :ai_analysis_runs, :status

    create_table :campaigns do |t|
      t.references :segment, null: false, foreign_key: true
      t.string :subject
      t.text :content
      t.string :status, null: false, default: "draft"
      t.timestamps
    end
  end
end
