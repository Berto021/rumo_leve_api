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

  private

  def serialize(entry)
    { id: entry.id, date: entry.recorded_on.to_s, weight: entry.weight.to_f, note: entry.note }
  end
end
