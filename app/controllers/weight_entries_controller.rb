class WeightEntriesController < ApplicationController
  def create
    entry = current_user.weight_entries.find_or_initialize_by(recorded_on: params[:date])
    was_new_record = entry.new_record?
    entry.weight = params[:weight]
    entry.note = params[:note]

    if entry.save
      render json: { weight_entry: serialize(entry) }, status: (was_new_record ? :created : :ok)
    else
      render json: { errors: entry.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    entry = current_user.weight_entries.find(params[:id])
    entry.recorded_on = params[:date] if params[:date].present?
    entry.weight = params[:weight] if params[:weight].present?
    entry.note = params[:note] if params.key?(:note)

    if entry.save
      render json: { weight_entry: serialize(entry) }, status: :ok
    else
      render json: { errors: entry.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    entry = current_user.weight_entries.find(params[:id])
    entry.destroy
    head :no_content
  end

  def history
    days = params[:days].presence&.to_i || 30
    if days <= 0
      render json: { errors: ["days deve ser um número positivo"] }, status: :unprocessable_content
      return
    end

    since = Date.current - days.days
    previous_weight = nil

    annotated = current_user.weight_entries.order(:recorded_on).map do |entry|
      variation = previous_weight && (entry.weight - previous_weight).round(2)
      previous_weight = entry.weight
      { entry: entry, variation: variation }
    end

    entries = annotated
      .select { |item| item[:entry].recorded_on >= since }
      .reverse
      .map { |item| serialize(item[:entry]).merge(variation: item[:variation]&.to_f) }

    render json: { entries: entries }, status: :ok
  end

  def chart
    period = params[:period].presence || "30"
    scope = current_user.weight_entries.order(:recorded_on)

    unless period == "all"
      days = Integer(period, exception: false)
      if days.nil? || days <= 0
        render json: { errors: ["period deve ser 7, 30, 90 ou all"] }, status: :unprocessable_content
        return
      end
      scope = scope.where("recorded_on >= ?", Date.current - days.days)
    end

    points = scope.map { |entry| { date: entry.recorded_on.to_s, weight: entry.weight.to_f } }
    render json: { points: points }, status: :ok
  end

  private

  def serialize(entry)
    { id: entry.id, date: entry.recorded_on.to_s, weight: entry.weight.to_f, note: entry.note }
  end
end
