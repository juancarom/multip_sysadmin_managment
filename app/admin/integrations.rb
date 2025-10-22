ActiveAdmin.register Integration do
  permit_params :project_id, :integration_type, :name, :active, settings: {}, credentials: {}

  scope :all, default: true
  scope :active
  scope("Jira") { |scope| scope.where(integration_type: 'jira') }
  scope("GitHub") { |scope| scope.where(integration_type: 'github') }
  scope("GitLab") { |scope| scope.where(integration_type: 'gitlab') }

  index do
    selectable_column
    id_column
    column :project do |integration|
      link_to integration.project.name, admin_project_path(integration.project)
    end
    column :integration_type do |integration|
      status_tag integration.integration_type, class: integration.integration_type
    end
    column :name
    column :active do |integration|
      status_tag integration.active ? 'Sí' : 'No', class: (integration.active ? 'yes' : 'no')
    end
    column :sync_status do |integration|
      status_tag integration.sync_status, class: integration.sync_status
    end
    column :last_sync_at do |integration|
      integration.last_sync_at&.strftime("%d/%m/%Y %H:%M") || 'Nunca'
    end
    actions defaults: true do |integration|
      item "Toggle", toggle_admin_integration_path(integration), method: :patch, class: 'member_link'
      item "Sync", sync_admin_integration_path(integration), method: :post, class: 'member_link' if integration.can_sync?
    end
  end

  filter :project
  filter :integration_type, as: :select, collection: Integration::INTEGRATION_TYPES
  filter :name
  filter :active
  filter :sync_status, as: :select, collection: Integration.sync_statuses
  filter :created_at

  form do |f|
    f.inputs do
      f.input :project, as: :select, collection: Project.all.map { |p| [p.name, p.id] }
      f.input :integration_type, as: :select, collection: Integration::INTEGRATION_TYPES
      f.input :name
      f.input :active, as: :boolean, 
              hint: 'Activa/desactiva esta integración. Solo las integraciones activas se sincronizan.'
      f.input :settings, as: :text, input_html: { rows: 8 }, 
              hint: 'JSON format. Ejemplo Jira: {"site_domain": "example.atlassian.net", "default_project_key": "PROJ"}'
      f.input :credentials, as: :text, input_html: { rows: 8 }, 
              hint: 'JSON format con credenciales. Ejemplo: {"access_token": "token_aqui"}. Se encriptará automáticamente.'
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :project do |integration|
        link_to integration.project.name, admin_project_path(integration.project)
      end
      row :integration_type do |integration|
        status_tag integration.integration_type, class: integration.integration_type
      end
      row :name
      row :active do |integration|
        status_tag integration.active ? 'Activa' : 'Inactiva', class: (integration.active ? 'yes' : 'no')
      end
      row :sync_status do |integration|
        status_tag integration.sync_status, class: integration.sync_status
      end
      row :last_sync_at
      row :error_message do |integration|
        integration.error_message.present? ? status_tag('Error', class: 'error') + " #{integration.error_message}" : '—'
      end
      row :settings do |integration|
        pre JSON.pretty_generate(integration.settings || {})
      end
      row :has_credentials do |integration|
        status_tag integration.credentials.present? ? 'Sí' : 'No', 
                   class: (integration.credentials.present? ? 'yes' : 'no')
      end
      row :created_at
      row :updated_at
    end

    panel "Acciones" do
      div class: 'action_items' do
        if resource.active?
          span link_to('Desactivar', toggle_admin_integration_path(resource), method: :patch, class: 'button')
        else
          span link_to('Activar', toggle_admin_integration_path(resource), method: :patch, class: 'button')
        end
        
        if resource.can_sync?
          span link_to('Sincronizar Ahora', sync_admin_integration_path(resource), method: :post, class: 'button')
        end

        if resource.credentials.present?
          span link_to('Probar Conexión', test_connection_admin_integration_path(resource), method: :post, class: 'button')
        end
      end
    end

    if resource.settings.present? && resource.settings['last_sync_data'].present?
      panel "Última Sincronización" do
        pre JSON.pretty_generate(resource.settings['last_sync_data'])
      end
    end
  end

  member_action :toggle, method: :patch do
    service = IntegrationService.new(resource)
    if service.toggle_active!
      redirect_to admin_integration_path(resource), notice: "Integración #{resource.active? ? 'activada' : 'desactivada'}"
    else
      redirect_to admin_integration_path(resource), alert: 'Error al cambiar estado'
    end
  end

  member_action :sync, method: :post do
    service = IntegrationService.new(resource)
    if service.sync!
      redirect_to admin_integration_path(resource), notice: 'Sincronización iniciada'
    else
      redirect_to admin_integration_path(resource), alert: 'Error al iniciar sincronización'
    end
  end

  member_action :test_connection, method: :post do
    if resource.test_connection
      redirect_to admin_integration_path(resource), notice: 'Conexión exitosa ✓'
    else
      redirect_to admin_integration_path(resource), alert: 'Error de conexión ✗'
    end
  end

  controller do
    def update
      # Convertir strings JSON a hashes antes de guardar
      if params[:integration][:settings].present?
        begin
          params[:integration][:settings] = JSON.parse(params[:integration][:settings])
        rescue JSON::ParserError
          # Mantener como string si no es JSON válido
        end
      end

      if params[:integration][:credentials].present?
        begin
          params[:integration][:credentials] = JSON.parse(params[:integration][:credentials])
        rescue JSON::ParserError
          # Mantener como string si no es JSON válido
        end
      end

      super
    end

    def create
      # Convertir strings JSON a hashes antes de guardar
      if params[:integration][:settings].present?
        begin
          params[:integration][:settings] = JSON.parse(params[:integration][:settings])
        rescue JSON::ParserError
          # Mantener como string si no es JSON válido
        end
      end

      if params[:integration][:credentials].present?
        begin
          params[:integration][:credentials] = JSON.parse(params[:integration][:credentials])
        rescue JSON::ParserError
          # Mantener como string si no es JSON válido
        end
      end

      super
    end
  end
end
