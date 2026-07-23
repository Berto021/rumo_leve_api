class PasswordMailer < ApplicationMailer
  def reset(user, token)
    @user = user
    @reset_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/redefinir-senha?token=#{token}"

    mail(to: @user.email, subject: "Redefinição de senha - Rumo Leve")
  end
end
