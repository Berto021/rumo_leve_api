class PasswordResetsController < ApplicationController
  skip_before_action :authenticate_request

  def create
    user = User.find_by(email: params[:email])

    if user
      token = user.generate_token_for(:password_reset)
      PasswordMailer.reset(user, token).deliver_later
    end

    render json: { message: "Se esse e-mail existir, enviamos um link de recuperação." }, status: :ok
  end

  def update
    user = User.find_by_token_for(:password_reset, params[:token])

    if user.nil?
      render json: { error: "Link inválido ou expirado" }, status: :unprocessable_content
      return
    end

    if user.update(password: params[:password])
      render json: { message: "Senha redefinida." }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_content
    end
  end
end
