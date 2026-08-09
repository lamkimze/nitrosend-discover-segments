class CreateSegmentMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :segment_memberships do |t|
      t.references :segment, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true

      t.timestamps
    end

    add_index :segment_memberships, [ :segment_id, :contact_id ], unique: true
  end
end
