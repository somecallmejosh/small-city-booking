class CreateBookingSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_slots do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :slot, null: false, foreign_key: true
    end

    add_index :booking_slots, [ :booking_id, :slot_id ], unique: true
  end
end
