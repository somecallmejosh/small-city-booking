class SendReminderEmailsJob < ApplicationJob
  queue_as :default

  def perform
    ids = Booking.confirmed
                 .joins(:slots)
                 .where(reminder_sent_at: nil)
                 .group("bookings.id")
                 .having(
                   "MIN(slots.starts_at) > ? AND MIN(slots.starts_at) <= ?",
                   23.hours.from_now,
                   25.hours.from_now
                 )
                 .pluck("bookings.id")

    return if ids.empty?

    Booking.where(id: ids).includes(:user, :slots).each do |booking|
      BookingMailer.reminder(booking).deliver_later
      booking.update_column(:reminder_sent_at, Time.current)
    end
  end
end
