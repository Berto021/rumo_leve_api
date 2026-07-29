require "test_helper"

class WeightEntryTest < ActiveSupport::TestCase
  def build_entry(overrides = {})
    users(:alice).weight_entries.build({ weight: 78.5, recorded_on: Date.current, note: nil }.merge(overrides))
  end

  test "is valid with weight, recorded_on and no note" do
    assert build_entry.valid?
  end

  test "requires a weight" do
    entry = build_entry(weight: nil)
    assert_not entry.valid?
    assert_includes entry.errors.full_messages, "Peso não pode ficar em branco"
  end

  test "requires a positive weight" do
    entry = build_entry(weight: 0)
    assert_not entry.valid?
    assert_includes entry.errors.full_messages, "Peso deve ser maior que 0"
  end

  test "requires recorded_on" do
    entry = build_entry(recorded_on: nil)
    assert_not entry.valid?
    assert_includes entry.errors.full_messages, "Data não pode ficar em branco"
  end

  test "rejects a future recorded_on" do
    entry = build_entry(recorded_on: Date.current + 1.day)
    assert_not entry.valid?
    assert_includes entry.errors.full_messages, "Data não pode ser no futuro"
  end

  test "rejects a duplicate recorded_on for the same user" do
    build_entry.save!
    duplicate = build_entry
    assert_not duplicate.valid?
    assert_includes duplicate.errors.full_messages, "Data já possui um registro"
  end

  test "allows the same recorded_on for different users" do
    build_entry.save!
    other_users_entry = users(:bob).weight_entries.build(weight: 80, recorded_on: Date.current)
    assert other_users_entry.valid?
  end
end
