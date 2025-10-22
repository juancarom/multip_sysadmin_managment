class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.text :description
      t.string :slug, null: false
      t.boolean :active, null: false, default: true
      t.json :settings

      t.timestamps
    end

    add_index :projects, :slug, unique: true
    add_index :projects, :active
  end
end
