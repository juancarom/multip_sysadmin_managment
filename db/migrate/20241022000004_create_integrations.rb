class CreateIntegrations < ActiveRecord::Migration[7.1]
  def change
    create_table :integrations do |t|
      t.references :project, null: false, foreign_key: true
      t.string :integration_type, null: false
      t.string :name, null: false
      t.boolean :active, null: false, default: false
      t.json :settings
      t.text :credentials # encrypted by ActiveRecord::Encryption
      t.datetime :last_sync_at
      t.integer :sync_status, null: false, default: 0
      t.text :error_message

      t.timestamps
    end

    add_index :integrations, %i[project_id integration_type], unique: true
    add_index :integrations, :integration_type
    add_index :integrations, :active
    add_index :integrations, :sync_status
  end
end
