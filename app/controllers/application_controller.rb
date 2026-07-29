class ApplicationController < ActionController::API
  include Authenticatable

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Registro não encontrado" }, status: :not_found
  end
end
