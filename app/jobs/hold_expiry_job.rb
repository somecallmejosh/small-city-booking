class HoldExpiryJob < ApplicationJob
  queue_as :default

  def perform
    expired_slot_ids = Slot.where(status: "held").where("held_until < ?", Time.current).pluck(:id)
    return if expired_slot_ids.empty?

    booking_ids = BookingSlot.joins(:booking)
                             .where(slot_id: expired_slot_ids)
                             .merge(Booking.pending)
                             .pluck(:booking_id)
                             .uniq

    Booking.where(id: booking_ids).update_all(status: "cancelled", cancelled_at: Time.current)

    Slot.where(id: expired_slot_ids).find_each do |slot|
      slot.update!(status: "open", held_by_user: nil, held_until: nil)
    end
  end
end
