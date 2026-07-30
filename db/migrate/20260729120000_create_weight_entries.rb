class CreateWeightEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :weight_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :weight, precision: 5, scale: 2, null: false
      t.date :recorded_on, null: false
      t.text :note

      t.timestamps
    end

    add_index :weight_entries, [:user_id, :recorded_on], unique: true
  end
end
