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

  test "updates an existing entry" do
    user = users(:alice)
    entry = user.weight_entries.create!(weight: 78.5, recorded_on: Date.current)

    patch "/weight_entries/#{entry.id}", params: { weight: 77.0, note: "Ajuste" }, headers: auth_headers(user)

    assert_response :success
    body = JSON.parse(response.body)["weight_entry"]
    assert_equal 77.0, body["weight"]
    assert_equal "Ajuste", body["note"]
  end

  test "rejects an invalid update" do
    user = users(:alice)
    entry = user.weight_entries.create!(weight: 78.5, recorded_on: Date.current)

    patch "/weight_entries/#{entry.id}", params: { weight: -5 }, headers: auth_headers(user)

    assert_response :unprocessable_content
    assert_includes JSON.parse(response.body)["errors"], "Peso deve ser maior que 0"
  end

  test "deletes an existing entry" do
    user = users(:alice)
    entry = user.weight_entries.create!(weight: 78.5, recorded_on: Date.current)

    delete "/weight_entries/#{entry.id}", headers: auth_headers(user)

    assert_response :no_content
    assert_equal 0, user.weight_entries.count
  end

  test "returns not found when updating another user's entry" do
    alice_entry = users(:alice).weight_entries.create!(weight: 78.5, recorded_on: Date.current)

    patch "/weight_entries/#{alice_entry.id}", params: { weight: 60.0 }, headers: auth_headers(users(:bob))

    assert_response :not_found
    assert_equal 78.5, alice_entry.reload.weight
  end

  test "returns not found when deleting another user's entry" do
    alice_entry = users(:alice).weight_entries.create!(weight: 78.5, recorded_on: Date.current)

    delete "/weight_entries/#{alice_entry.id}", headers: auth_headers(users(:bob))

    assert_response :not_found
    assert alice_entry.reload.persisted?
  end

  test "returns history most-recent-first with day-over-day variation" do
    user = users(:alice)
    user.weight_entries.create!(weight: 80.0, recorded_on: 10.days.ago.to_date)
    user.weight_entries.create!(weight: 79.0, recorded_on: 5.days.ago.to_date)
    user.weight_entries.create!(weight: 78.5, recorded_on: Date.current)

    get "/weight_entries/history", headers: auth_headers(user)

    assert_response :success
    entries = JSON.parse(response.body)["entries"]
    assert_equal 3, entries.length
    assert_equal Date.current.to_s, entries[0]["date"]
    assert_equal(-0.5, entries[0]["variation"])
    assert_equal(-1.0, entries[1]["variation"])
    assert_nil entries[2]["variation"]
  end

  test "filters history by days but still bases variation on the last existing entry" do
    user = users(:alice)
    user.weight_entries.create!(weight: 80.0, recorded_on: 10.days.ago.to_date)
    user.weight_entries.create!(weight: 78.5, recorded_on: Date.current)

    get "/weight_entries/history", params: { days: 3 }, headers: auth_headers(user)

    assert_response :success
    entries = JSON.parse(response.body)["entries"]
    assert_equal 1, entries.length
    assert_equal Date.current.to_s, entries[0]["date"]
    assert_equal(-1.5, entries[0]["variation"])
  end

  test "returns an empty list when there is no history" do
    get "/weight_entries/history", headers: auth_headers(users(:alice))

    assert_response :success
    assert_equal [], JSON.parse(response.body)["entries"]
  end

  test "rejects a non-positive days param" do
    get "/weight_entries/history", params: { days: 0 }, headers: auth_headers(users(:alice))

    assert_response :unprocessable_content
  end
end
