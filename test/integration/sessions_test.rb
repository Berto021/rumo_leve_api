require "test_helper"

class SessionsTest < ActionDispatch::IntegrationTest
  test "logs in with valid credentials and returns a usable token" do
    user = users(:alice)
    post "/login", params: { email: user.email, password: "password123" }

    assert_response :success
    body = JSON.parse(response.body)
    assert body["token"].present?
    assert_equal user.email, body["user"]["email"]

    decoded = JsonWebToken.decode(body["token"])
    assert_equal user.id, decoded[:user_id]
  end

  test "rejects the wrong password" do
    post "/login", params: { email: users(:alice).email, password: "wrongpassword" }

    assert_response :unauthorized
    assert_equal "E-mail ou senha inválidos", JSON.parse(response.body)["error"]
  end

  test "rejects an unknown email with the same generic message" do
    post "/login", params: { email: "ghost@example.com", password: "whatever123" }

    assert_response :unauthorized
    assert_equal "E-mail ou senha inválidos", JSON.parse(response.body)["error"]
  end
end
