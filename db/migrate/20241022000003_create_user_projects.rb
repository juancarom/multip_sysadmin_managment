class CreateUserProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :user_projects do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.integer :role, null: false, default: 0

      t.timestamps
    end

    add_index :user_projects, %i[user_id project_id], unique: true
    add_index :user_projects, :role
  end
end
