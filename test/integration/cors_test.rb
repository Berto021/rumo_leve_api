require "test_helper"

class CorsTest < ActionDispatch::IntegrationTest
  test "allows a configured frontend dev origin" do
    post "/login",
      params: { email: "ghost@example.com", password: "x" },
      headers: { "Origin" => "http://localhost:5173" }

    assert_equal "http://localhost:5173", response.headers["Access-Control-Allow-Origin"]
  end

  test "does not allow an unlisted origin" do
    post "/login",
      params: { email: "ghost@example.com", password: "x" },
      headers: { "Origin" => "http://evil.example.com" }

    assert_nil response.headers["Access-Control-Allow-Origin"]
  end
end
