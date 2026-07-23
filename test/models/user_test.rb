require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid with name, email and password" do
    user = User.new(name: "Bruno", email: "bruno@example.com", password: "password123")
    assert user.valid?
  end

  test "invalid without a name" do
    user = User.new(email: "bruno@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors.full_messages, "Nome não pode ficar em branco"
  end

  test "invalid without a valid email" do
    user = User.new(name: "Bruno", email: "not-an-email", password: "password123")
    assert_not user.valid?
    assert_includes user.errors.full_messages, "E-mail não é válido"
  end

  test "invalid with a duplicate email" do
    user = User.new(name: "Outro", email: users(:alice).email, password: "password123")
    assert_not user.valid?
    assert_includes user.errors.full_messages, "E-mail já está em uso"
  end

  test "invalid with a short password" do
    user = User.new(name: "Bruno", email: "bruno@example.com", password: "short")
    assert_not user.valid?
    assert_includes user.errors.full_messages, "Senha é muito curta (mínimo de 8 caracteres)"
  end

  test "normalizes email to lowercase and trimmed" do
    user = User.create!(name: "Bruno", email: "  Bruno@Example.com  ", password: "password123")
    assert_equal "bruno@example.com", user.email
  end

  test "finds by email regardless of case, thanks to normalization" do
    assert_equal users(:alice), User.find_by(email: "ALICE@example.com")
  end

  test "authenticates with the correct password" do
    assert users(:alice).authenticate("password123")
  end

  test "does not authenticate with the wrong password" do
    assert_not users(:alice).authenticate("wrongpassword")
  end

  test "generates and finds a valid password reset token" do
    user = users(:alice)
    token = user.generate_token_for(:password_reset)
    assert_equal user, User.find_by_token_for(:password_reset, token)
  end

  test "password reset token is invalid after the password changes" do
    user = users(:alice)
    token = user.generate_token_for(:password_reset)
    user.update!(password: "newpassword123")
    assert_nil User.find_by_token_for(:password_reset, token)
  end

  test "password reset token expires after 30 minutes" do
    user = users(:alice)
    token = user.generate_token_for(:password_reset)
    travel 31.minutes
    assert_nil User.find_by_token_for(:password_reset, token)
  end
end
