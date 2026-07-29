class WeightEntry < ApplicationRecord
  belongs_to :user

  validates :weight, presence: true, numericality: { greater_than: 0 }
  validates :recorded_on, presence: true
  validates :recorded_on, uniqueness: { scope: :user_id, message: "já possui um registro" }
  validate :recorded_on_cannot_be_in_the_future

  private

  def recorded_on_cannot_be_in_the_future
    return if recorded_on.blank?

    errors.add(:recorded_on, "não pode ser no futuro") if recorded_on > Date.current
  end
end
