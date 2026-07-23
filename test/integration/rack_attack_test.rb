require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear
  end

  teardown do
    Rack::Attack.enabled = false
    Rack::Attack.cache.store.clear
  end

  test "throttles repeated login attempts from the same IP" do
    6.times do
      post "/login", params: { email: "ghost@example.com", password: "x" }
    end

    assert_response 429
  end

  test "throttles repeated password reset requests for the same email" do
    4.times do
      post "/password_resets", params: { email: "someone@example.com" }
    end

    assert_response 429
  end
end
