class UsersController < ApplicationController
  def create
    user = User.new(user_params)

    if user.save
      render json: { user: serialize(user) }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.permit(:name, :email, :password)
  end

  def serialize(user)
    { id: user.id, name: user.name, email: user.email }
  end
end
