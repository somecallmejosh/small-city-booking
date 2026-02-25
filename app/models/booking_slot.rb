class BookingSlot < ApplicationRecord
  belongs_to :booking
  belongs_to :slot

  validates :slot_id, uniqueness: { scope: :booking_id }
end
