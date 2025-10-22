module IntegrationAdapters
  class BaseAdapter
    attr_reader :integration

    def initialize(integration)
      @integration = integration
    end

    def sync
      raise NotImplementedError, 'Subclasses must implement #sync'
    end

    def test_connection
      raise NotImplementedError, 'Subclasses must implement #test_connection'
    end

    def add_user_to_project(user_email, project_settings = {})
      raise NotImplementedError, 'Subclasses must implement #add_user_to_project'
    end

    def remove_user_from_project(user_email)
      raise NotImplementedError, 'Subclasses must implement #remove_user_from_project'
    end

    def list_users
      raise NotImplementedError, 'Subclasses must implement #list_users'
    end

    protected

    def credentials
      @credentials ||= integration.formatted_credentials
    end

    def settings
      @settings ||= integration.settings || {}
    end

    def http_client
      @http_client ||= Faraday.new do |conn|
        conn.request :json
        conn.response :json
        conn.adapter :net_http
        conn.request :retry, max: 3, interval: 0.5
      end
    end

    def log_info(message)
      Rails.logger.info "[#{integration.integration_type.upcase}] #{message}"
    end

    def log_error(message, error = nil)
      full_message = "[#{integration.integration_type.upcase}] #{message}"
      full_message += " - #{error.message}" if error
      Rails.logger.error full_message
    end

    def handle_api_error(response)
      error_message = "API Error: #{response.status}"

      if response.body.is_a?(Hash)
        error_message += " - #{response.body['message'] || response.body['error'] || 'Unknown error'}"
      end

      raise StandardError, error_message
    end
  end
end
