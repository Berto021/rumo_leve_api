module JsonWebToken
  SECRET = Rails.application.secret_key_base

  def self.encode(payload, exp = 24.hours.from_now)
    payload = payload.merge(exp: exp.to_i)
    JWT.encode(payload, SECRET)
  end

  def self.decode(token)
    body = JWT.decode(token, SECRET)[0]
    ActiveSupport::HashWithIndifferentAccess.new(body)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
