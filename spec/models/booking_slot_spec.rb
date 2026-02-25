require "rails_helper"

RSpec.describe BookingSlot, type: :model do
  it "is valid with a booking and slot" do
    booking_slot = build(:booking_slot)
    expect(booking_slot).to be_valid
  end

  it "prevents the same slot appearing twice in the same booking" do
    booking = create(:booking)
    slot    = create(:slot)
    create(:booking_slot, booking: booking, slot: slot)

    duplicate = build(:booking_slot, booking: booking, slot: slot)
    expect(duplicate).not_to be_valid
  end
end
