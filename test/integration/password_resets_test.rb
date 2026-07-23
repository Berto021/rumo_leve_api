require "test_helper"

class PasswordResetsTest < ActionDispatch::IntegrationTest
  test "always returns the same generic message, whether or not the email exists" do
    post "/password_resets", params: { email: users(:alice).email }
    assert_response :success
    assert_equal "Se esse e-mail existir, enviamos um link de recuperação.", JSON.parse(response.body)["message"]

    post "/password_resets", params: { email: "ghost@example.com" }
    assert_response :success
    assert_equal "Se esse e-mail existir, enviamos um link de recuperação.", JSON.parse(response.body)["message"]
  end

  test "enqueues a reset email only when the user exists" do
    assert_enqueued_jobs 1 do
      post "/password_resets", params: { email: users(:alice).email }
    end

    assert_enqueued_jobs 0 do
      post "/password_resets", params: { email: "ghost@example.com" }
    end
  end

  test "resets the password with a valid token" do
    user = users(:alice)
    token = user.generate_token_for(:password_reset)

    patch "/password_resets/#{token}", params: { password: "newpassword123" }

    assert_response :success
    assert_equal "Senha redefinida.", JSON.parse(response.body)["message"]
    assert user.reload.authenticate("newpassword123")
  end

  test "rejects an invalid token" do
    patch "/password_resets/does-not-exist", params: { password: "newpassword123" }

    assert_response :unprocessable_content
    assert_equal "Link inválido ou expirado", JSON.parse(response.body)["error"]
  end

  test "rejects a password that is too short" do
    user = users(:alice)
    token = user.generate_token_for(:password_reset)

    patch "/password_resets/#{token}", params: { password: "short" }

    assert_response :unprocessable_content
    assert_includes JSON.parse(response.body)["errors"], "Senha é muito curta (mínimo de 8 caracteres)"
  end
end
