module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
  end

  private

  def authenticate_request
    header = request.headers["Authorization"]
    token = header.split(" ").last if header
    decoded = token && JsonWebToken.decode(token)

    @current_user = decoded && User.find_by(id: decoded[:user_id])

    render json: { error: "Não autorizado" }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end
