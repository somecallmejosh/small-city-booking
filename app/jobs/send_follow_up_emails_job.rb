class SendFollowUpEmailsJob < ApplicationJob
  queue_as :default

  def perform
    ids = Booking.completed
                 .joins(:slots)
                 .where(follow_up_sent_at: nil)
                 .group("bookings.id")
                 .having("MAX(slots.starts_at) <= ?", 4.hours.ago)
                 .pluck("bookings.id")

    return if ids.empty?

    Booking.where(id: ids).includes(:user).each do |booking|
      BookingMailer.follow_up(booking).deliver_later
      booking.update_column(:follow_up_sent_at, Time.current)
    end
  end
end
