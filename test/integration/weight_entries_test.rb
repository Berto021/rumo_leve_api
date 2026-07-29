require "test_helper"

class WeightEntriesTest < ActionDispatch::IntegrationTest
  test "rejects requests without a token" do
    post "/weight_entries", params: { date: Date.current.to_s, weight: 78.5 }

    assert_response :unauthorized
    assert_equal "Não autorizado", JSON.parse(response.body)["error"]
  end

  test "creates a new weight entry for the given date" do
    user = users(:alice)

    post "/weight_entries",
      params: { date: Date.current.to_s, weight: 78.5, note: "Café da manhã pesado" },
      headers: auth_headers(user)

    assert_response :created
    body = JSON.parse(response.body)["weight_entry"]
    assert_equal Date.current.to_s, body["date"]
    assert_equal 78.5, body["weight"]
    assert_equal "Café da manhã pesado", body["note"]
    assert_equal 1, user.weight_entries.count
  end

  test "upserts instead of duplicating when posting the same date twice" do
    user = users(:alice)
    post "/weight_entries", params: { date: Date.current.to_s, weight: 78.5 }, headers: auth_headers(user)
    assert_response :created

    post "/weight_entries", params: { date: Date.current.to_s, weight: 79.0 }, headers: auth_headers(user)
    assert_response :success

    body = JSON.parse(response.body)["weight_entry"]
    assert_equal 79.0, body["weight"]
    assert_equal 1, user.weight_entries.count
  end

  test "rejects an invalid weight" do
    post "/weight_entries",
      params: { date: Date.current.to_s, weight: 0 },
      headers: auth_headers(users(:alice))

    assert_response :unprocessable_content
    assert_includes JSON.parse(response.body)["errors"], "Peso deve ser maior que 0"
  end
end
