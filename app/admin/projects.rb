ActiveAdmin.register Project do
  menu label: '📁 Proyectos', priority: 1
  permit_params :name, :description, :active, settings: {}

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column :description, truncate: 50
    column :active do |project|
      status_tag project.active ? 'Activo' : 'Inactivo', class: (project.active ? 'yes' : 'no')
    end
    column :integrations do |project|
      "#{project.active_integrations.count} / #{project.integrations.count}"
    end
    column :users do |project|
      project.users.count
    end
    column :created_at
    actions
  end

  filter :name
  filter :slug
  filter :active
  filter :created_at

  form do |f|
    f.inputs do
      f.input :name
      f.input :description
      f.input :active
      f.input :settings, as: :text, input_html: { rows: 5 },
                         hint: 'JSON format: {"key": "value"}'
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :description
      row :active do |project|
        status_tag project.active ? 'Activo' : 'Inactivo', class: (project.active ? 'yes' : 'no')
      end
      row :settings do |project|
        pre JSON.pretty_generate(project.settings || {})
      end
      row :created_at
      row :updated_at
    end

    panel 'Integraciones' do
      table_for project.integrations do
        column 'Tipo' do |integration|
          status_tag integration.integration_type
        end
        column 'Nombre' do |integration|
          link_to integration.name, admin_integration_path(integration)
        end
        column 'Estado' do |integration|
          status_tag integration.active ? 'Activa' : 'Inactiva', class: (integration.active ? 'yes' : 'no')
        end
        column 'Sincronización' do |integration|
          status_tag integration.sync_status
        end
        column 'Última sync' do |integration|
          integration.last_sync_at&.strftime('%d/%m/%Y %H:%M') || 'Nunca'
        end
      end
    end

    panel 'Usuarios' do
      table_for project.user_projects.includes(:user) do
        column 'Usuario' do |up|
          link_to up.user.name, admin_user_path(up.user)
        end
        column 'Email' do |up|
          up.user.email
        end
        column 'Rol en Proyecto' do |up|
          status_tag up.role
        end
        column 'Rol Global' do |up|
          status_tag up.user.role
        end
      end
    end
  end
end
