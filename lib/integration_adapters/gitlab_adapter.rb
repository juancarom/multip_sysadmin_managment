module IntegrationAdapters
  class GitlabAdapter < BaseAdapter
    def sync
      log_info "Starting GitLab sync for project #{integration.project.name}"

      projects = list_projects
      members = list_members

      sync_data = {
        projects: projects,
        members: members,
        synced_at: Time.current
      }

      integration.update!(settings: integration.settings.merge(last_sync_data: sync_data))

      log_info "GitLab sync completed. Found #{projects.size} projects and #{members.size} members"
      true
    end

    def test_connection
      response = http_client.get do |req|
        req.url "#{base_url}/api/v4/user"
        req.headers['Authorization'] = "Bearer #{credentials['access_token']}"
      end

      response.success?
    rescue StandardError => e
      log_error('Connection test failed', e)
      false
    end

    def add_user_to_project(user_email, project_settings = {})
      user_id = find_user_id_by_email(user_email)
      project_id = project_settings['project_id'] || settings['default_project_id']
      access_level = project_settings['access_level'] || 30 # Developer level

      raise StandardError, 'Project ID not specified' if project_id.blank?
      raise StandardError, "User not found for email #{user_email}" if user_id.blank?

      # Add user to GitLab project
      response = http_client.post do |req|
        req.url "#{base_url}/api/v4/projects/#{project_id}/members"
        req.headers['Authorization'] = "Bearer #{credentials['access_token']}"
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          user_id: user_id,
          access_level: access_level
        }
      end

      handle_api_error(response) unless response.success?

      log_info "Added user #{user_email} to GitLab project #{project_id}"
      true
    end

    def remove_user_from_project(user_email)
      user_id = find_user_id_by_email(user_email)
      project_id = settings['default_project_id']

      raise StandardError, 'Project ID not specified' if project_id.blank?
      raise StandardError, "User not found for email #{user_email}" if user_id.blank?

      # Remove user from GitLab project
      response = http_client.delete do |req|
        req.url "#{base_url}/api/v4/projects/#{project_id}/members/#{user_id}"
        req.headers['Authorization'] = "Bearer #{credentials['access_token']}"
      end

      handle_api_error(response) unless response.success?

      log_info "Removed user #{user_email} from GitLab project #{project_id}"
      true
    end

    def list_users
      list_members
    end

    def list_projects
      response = http_client.get do |req|
        req.url "#{base_url}/api/v4/projects"
        req.headers['Authorization'] = "Bearer #{credentials['access_token']}"
        req.params['membership'] = true
        req.params['per_page'] = 100
      end

      handle_api_error(response) unless response.success?

      response.body.map do |project|
        {
          id: project['id'],
          name: project['name'],
          path: project['path'],
          namespace: project['namespace']['name'],
          visibility: project['visibility'],
          description: project['description']
        }
      end
    end

    def list_members
      project_id = settings['default_project_id']
      return [] if project_id.blank?

      response = http_client.get do |req|
        req.url "#{base_url}/api/v4/projects/#{project_id}/members/all"
        req.headers['Authorization'] = "Bearer #{credentials['access_token']}"
        req.params['per_page'] = 100
      end

      handle_api_error(response) unless response.success?

      response.body.map do |member|
        {
          id: member['id'],
          username: member['username'],
          email: member['email'],
          name: member['name'],
          access_level: member['access_level']
        }
      end
    end

    private

    def base_url
      @base_url ||= credentials['base_url'] || settings['base_url'] || 'https://gitlab.com'
    end

    def find_user_id_by_email(email)
      response = http_client.get do |req|
        req.url "#{base_url}/api/v4/users"
        req.headers['Authorization'] = "Bearer #{credentials['access_token']}"
        req.params['search'] = email
      end

      handle_api_error(response) unless response.success?

      user = response.body.find { |u| u['email'] == email }
      user&.dig('id')
    end
  end
end
