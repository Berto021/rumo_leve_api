class User < ApplicationRecord
  has_secure_password

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true,
                     format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  generates_token_for :password_reset, expires_in: 30.minutes do
    password_salt.last(10)
  end
end
