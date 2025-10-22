module IntegrationAdapters
  class JiraAdapter < BaseAdapter
    BASE_URL = 'https://api.atlassian.com'

    def sync
      log_info "Starting Jira sync for project #{integration.project.name}"

      users = list_users
      projects = list_projects

      sync_data = {
        users: users,
        projects: projects,
        synced_at: Time.current
      }

      integration.update!(settings: integration.settings.merge(last_sync_data: sync_data))

      log_info "Jira sync completed. Found #{users.size} users and #{projects.size} projects"
      true
    end

    def test_connection
      response = http_client.get do |req|
        req.url "#{BASE_URL}/ex/jira/#{site_domain}/rest/api/3/myself"
        req.headers['Authorization'] = "Bearer #{credentials['access_token']}"
        req.headers['Accept'] = 'application/json'
      end

      response.success?
    rescue StandardError => e
      log_error('Connection test failed', e)
      false
    end

    def add_user_to_project(user_email, project_settings = {})
      project_key = project_settings['project_key'] || settings['default_project_key']

      raise StandardError, 'Project key not specified' if project_key.blank?

      # Add user to Jira project
      response = http_client.post do |req|
        req.url "#{BASE_URL}/ex/jira/#{site_domain}/rest/api/3/project/#{project_key}/role/10000"
        req.headers['Authorization'] = "Bearer #{credentials['access_token']}"
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          user: [user_email]
        }
      end

      handle_api_error(response) unless response.success?

      log_info "Added user #{user_email} to Jira project #{project_key}"
      true
    end

    def remove_user_from_project(user_email)
      project_key = settings['default_project_key']

      raise StandardError, 'Project key not specified' if project_key.blank?

      # Remove user from Jira project
      response = http_client.delete do |req|
        req.url "#{BASE_URL}/ex/jira/#{site_domain}/rest/api/3/project/#{project_key}/role/10000"
        req.headers['Authorization'] = "Bearer #{credentials['access_token']}"
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          user: [user_email]
        }
      end

      handle_api_error(response) unless response.success?

      log_info "Removed user #{user_email} from Jira project #{project_key}"
      true
    end

    def list_users
      response = http_client.get do |req|
        req.url "#{BASE_URL}/ex/jira/#{site_domain}/rest/api/3/users/search"
        req.headers['Authorization'] = "Bearer #{credentials['access_token']}"
        req.params['maxResults'] = 1000
      end

      handle_api_error(response) unless response.success?

      response.body.map do |user|
        {
          id: user['accountId'],
          email: user['emailAddress'],
          name: user['displayName'],
          active: user['active']
        }
      end
    end

    def list_projects
      response = http_client.get do |req|
        req.url "#{BASE_URL}/ex/jira/#{site_domain}/rest/api/3/project/search"
        req.headers['Authorization'] = "Bearer #{credentials['access_token']}"
        req.params['maxResults'] = 1000
      end

      handle_api_error(response) unless response.success?

      response.body['values'].map do |project|
        {
          id: project['id'],
          key: project['key'],
          name: project['name'],
          project_type: project['projectTypeKey']
        }
      end
    end

    private

    def site_domain
      @site_domain ||= credentials['site_domain'] || settings['site_domain']
      raise StandardError, 'Jira site domain not configured' if @site_domain.blank?

      @site_domain
    end
  end
end
