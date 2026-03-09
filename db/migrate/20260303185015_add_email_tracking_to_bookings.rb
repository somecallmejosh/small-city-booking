class AddEmailTrackingToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :reminder_sent_at, :datetime
    add_column :bookings, :follow_up_sent_at, :datetime
  end
end
