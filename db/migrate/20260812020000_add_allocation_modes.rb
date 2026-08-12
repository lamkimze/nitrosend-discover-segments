class AddAllocationModes < ActiveRecord::Migration[8.1]
  def change
    add_column :contacts, :pending_allocation, :boolean, null: false, default: false
    add_index :contacts, :pending_allocation

    add_column :ai_analysis_runs, :mode, :string, null: false, default: "full"
    add_index :ai_analysis_runs, :mode
  end
end
