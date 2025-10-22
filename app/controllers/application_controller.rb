class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Health check endpoint (sin autenticación)
  def health
    render json: { status: 'ok', timestamp: Time.current }
  end

  private

  def user_not_authorized
    flash[:alert] = 'No estás autorizado para realizar esta acción.'
    redirect_to(request.referrer || root_path)
  end
end
