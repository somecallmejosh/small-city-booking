class CreateStudioSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :studio_settings do |t|
      t.integer :hourly_rate_cents, null: false
      t.string :studio_name
      t.text :studio_description
      t.integer :cancellation_hours, default: 24, null: false

      t.timestamps
    end
  end
end
