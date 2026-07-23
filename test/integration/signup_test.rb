require "test_helper"

class SignupTest < ActionDispatch::IntegrationTest
  test "creates a user with valid params" do
    post "/signup", params: { name: "Bruno", email: "bruno@example.com", password: "password123" }

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Bruno", body["user"]["name"]
    assert_equal "bruno@example.com", body["user"]["email"]
    assert body["user"]["id"].present?
    assert_nil body["token"]
  end

  test "rejects a duplicate email" do
    post "/signup", params: { name: "Outro", email: users(:alice).email, password: "password123" }

    assert_response :unprocessable_content
    body = JSON.parse(response.body)
    assert_includes body["errors"], "E-mail já está em uso"
  end

  test "rejects a short password" do
    post "/signup", params: { name: "Bruno", email: "bruno2@example.com", password: "short" }

    assert_response :unprocessable_content
    body = JSON.parse(response.body)
    assert_includes body["errors"], "Senha é muito curta (mínimo de 8 caracteres)"
  end
end
