module Api
  module V1
    class BaseController < ActionController::API
      include Pundit::Authorization

      before_action :authenticate_user!

      rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
      rescue_from ActiveRecord::RecordNotFound, with: :not_found

      private

      def user_not_authorized
        render json: { error: 'No autorizado' }, status: :forbidden
      end

      def not_found
        render json: { error: 'No encontrado' }, status: :not_found
      end
    end
  end
end
