ActiveAdmin.register User do
  permit_params :email, :name, :role, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :email
    column :name
    column :role do |user|
      status_tag user.role, class: user.role
    end
    column :created_at
    column :projects do |user|
      user.projects.count
    end
    actions
  end

  filter :email
  filter :name
  filter :role, as: :select, collection: User.roles
  filter :created_at

  form do |f|
    f.inputs do
      f.input :email
      f.input :name
      f.input :role, as: :select, collection: User.roles.keys
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :email
      row :name
      row :role do |user|
        status_tag user.role, class: user.role
      end
      row :created_at
      row :updated_at
    end

    panel 'Proyectos' do
      table_for user.user_projects.includes(:project) do
        column 'Proyecto' do |up|
          link_to up.project.name, admin_project_path(up.project)
        end
        column 'Rol' do |up|
          status_tag up.role
        end
        column 'Agregado' do |up|
          up.created_at.strftime('%d/%m/%Y')
        end
      end
    end
  end
end
