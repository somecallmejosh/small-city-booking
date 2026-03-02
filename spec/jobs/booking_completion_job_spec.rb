require "rails_helper"

RSpec.describe BookingCompletionJob, type: :job do
  def booking_with_slot(status:, starts_at:)
    booking = create(:booking, status: status)
    slot = create(:slot, starts_at: starts_at, status: "reserved")
    create(:booking_slot, booking: booking, slot: slot)
    booking
  end

  describe "#perform" do
    it "marks a confirmed booking as completed when all slots have ended" do
      booking = booking_with_slot(status: "confirmed", starts_at: 2.hours.ago)

      described_class.new.perform

      expect(booking.reload.status).to eq("completed")
    end

    it "does not complete a confirmed booking with future slots" do
      booking = booking_with_slot(status: "confirmed", starts_at: 1.day.from_now)

      described_class.new.perform

      expect(booking.reload.status).to eq("confirmed")
    end

    it "does not complete a booking whose last slot ended less than one hour ago" do
      # Slot started 30 minutes ago — ends 30 minutes from now
      booking = booking_with_slot(status: "confirmed", starts_at: 30.minutes.ago)

      described_class.new.perform

      expect(booking.reload.status).to eq("confirmed")
    end

    it "does not complete a multi-slot booking when any slot is still in the future" do
      booking = create(:booking, status: "confirmed")
      past_slot   = create(:slot, starts_at: 2.hours.ago,     status: "reserved")
      future_slot = create(:slot, starts_at: 1.day.from_now,  status: "reserved")
      create(:booking_slot, booking: booking, slot: past_slot)
      create(:booking_slot, booking: booking, slot: future_slot)

      described_class.new.perform

      expect(booking.reload.status).to eq("confirmed")
    end

    it "does not affect pending bookings with past slots" do
      booking = booking_with_slot(status: "pending", starts_at: 2.hours.ago)

      described_class.new.perform

      expect(booking.reload.status).to eq("pending")
    end

    it "does not affect cancelled bookings with past slots" do
      booking = booking_with_slot(status: "cancelled", starts_at: 2.hours.ago)

      described_class.new.perform

      expect(booking.reload.status).to eq("cancelled")
    end
  end
end
