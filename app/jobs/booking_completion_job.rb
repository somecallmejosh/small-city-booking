class BookingCompletionJob < ApplicationJob
  queue_as :default

  def perform
    completed_ids = Booking.confirmed
                            .joins(:slots)
                            .group("bookings.id")
                            .having("MAX(slots.starts_at) <= ?", 1.hour.ago)
                            .pluck("bookings.id")

    Booking.where(id: completed_ids).update_all(status: "completed")
  end
end
