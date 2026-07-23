class Rack::Attack
  # Store isolado em memória — independe do cache_store da aplicação
  # (em test/dev o cache_store da app costuma ser :null_store, que não guarda nada).
  self.cache.store = ActiveSupport::Cache::MemoryStore.new

  throttle("login/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/login" && req.post?
  end

  throttle("login/email", limit: 5, period: 20.minutes) do |req|
    req.params["email"].to_s.downcase.presence if req.path == "/login" && req.post?
  end

  throttle("password_reset/ip", limit: 3, period: 15.minutes) do |req|
    req.ip if req.path == "/password_resets" && req.post?
  end

  throttle("password_reset/email", limit: 3, period: 15.minutes) do |req|
    req.params["email"].to_s.downcase.presence if req.path == "/password_resets" && req.post?
  end
end
