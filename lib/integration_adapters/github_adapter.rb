module IntegrationAdapters
  class GithubAdapter < BaseAdapter
    BASE_URL = 'https://api.github.com'

    def sync
      log_info "Starting GitHub sync for project #{integration.project.name}"

      repositories = list_repositories
      collaborators = list_collaborators

      sync_data = {
        repositories: repositories,
        collaborators: collaborators,
        synced_at: Time.current
      }

      integration.update!(settings: integration.settings.merge(last_sync_data: sync_data))

      log_info "GitHub sync completed. Found #{repositories.size} repositories and #{collaborators.size} collaborators"
      true
    end

    def test_connection
      response = http_client.get do |req|
        req.url "#{BASE_URL}/user"
        req.headers['Authorization'] = "token #{credentials['access_token']}"
        req.headers['Accept'] = 'application/vnd.github.v3+json'
      end

      response.success?
    rescue StandardError => e
      log_error('Connection test failed', e)
      false
    end

    def add_user_to_project(user_email, project_settings = {})
      username = project_settings['username'] || find_username_by_email(user_email)
      repository = project_settings['repository'] || settings['default_repository']

      raise StandardError, 'Repository not specified' if repository.blank?
      raise StandardError, "Username not found for email #{user_email}" if username.blank?

      # Add user as collaborator to repository
      response = http_client.put do |req|
        req.url "#{BASE_URL}/repos/#{organization}/#{repository}/collaborators/#{username}"
        req.headers['Authorization'] = "token #{credentials['access_token']}"
        req.headers['Accept'] = 'application/vnd.github.v3+json'
        req.body = {
          permission: project_settings['permission'] || 'push'
        }
      end

      handle_api_error(response) unless response.success?

      log_info "Added user #{username} to GitHub repository #{organization}/#{repository}"
      true
    end

    def remove_user_from_project(user_email)
      username = find_username_by_email(user_email)
      repository = settings['default_repository']

      raise StandardError, 'Repository not specified' if repository.blank?
      raise StandardError, "Username not found for email #{user_email}" if username.blank?

      # Remove user from repository
      response = http_client.delete do |req|
        req.url "#{BASE_URL}/repos/#{organization}/#{repository}/collaborators/#{username}"
        req.headers['Authorization'] = "token #{credentials['access_token']}"
        req.headers['Accept'] = 'application/vnd.github.v3+json'
      end

      handle_api_error(response) unless response.success?

      log_info "Removed user #{username} from GitHub repository #{organization}/#{repository}"
      true
    end

    def list_users
      list_collaborators
    end

    def list_repositories
      response = http_client.get do |req|
        req.url "#{BASE_URL}/orgs/#{organization}/repos"
        req.headers['Authorization'] = "token #{credentials['access_token']}"
        req.headers['Accept'] = 'application/vnd.github.v3+json'
        req.params['per_page'] = 100
        req.params['type'] = 'all'
      end

      handle_api_error(response) unless response.success?

      response.body.map do |repo|
        {
          id: repo['id'],
          name: repo['name'],
          full_name: repo['full_name'],
          private: repo['private'],
          description: repo['description']
        }
      end
    end

    def list_collaborators
      repository = settings['default_repository']
      return [] if repository.blank?

      response = http_client.get do |req|
        req.url "#{BASE_URL}/repos/#{organization}/#{repository}/collaborators"
        req.headers['Authorization'] = "token #{credentials['access_token']}"
        req.headers['Accept'] = 'application/vnd.github.v3+json'
        req.params['per_page'] = 100
      end

      handle_api_error(response) unless response.success?

      response.body.map do |collaborator|
        {
          id: collaborator['id'],
          username: collaborator['login'],
          email: collaborator['email'],
          name: collaborator['name'],
          permissions: collaborator['permissions']
        }
      end
    end

    private

    def organization
      @organization ||= credentials['organization'] || settings['organization']
      raise StandardError, 'GitHub organization not configured' if @organization.blank?

      @organization
    end

    def find_username_by_email(email)
      # In a real implementation, you might need to search for users by email
      # GitHub API doesn't directly support email search, so this is a simplified version

      # Try to extract username from email if it follows a pattern
      if email.include?('@') && settings['email_to_username_mapping']
        return settings['email_to_username_mapping'][email]
      end

      # You might need to maintain a mapping in your database or use another approach
      raise StandardError, "Username mapping not found for email #{email}"
    end
  end
end
