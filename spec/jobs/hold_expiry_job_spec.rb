require "rails_helper"

RSpec.describe HoldExpiryJob, type: :job do
  describe "#perform" do
    it "releases expired held slots" do
      slot = create(:slot, :held, held_until: 2.minutes.ago)

      described_class.new.perform

      slot.reload
      expect(slot.status).to eq("open")
      expect(slot.held_by_user).to be_nil
      expect(slot.held_until).to be_nil
    end

    it "cancels pending bookings associated with expired slots" do
      slot = create(:slot, :held, held_until: 2.minutes.ago)
      booking = create(:booking, status: "pending")
      create(:booking_slot, booking: booking, slot: slot)

      described_class.new.perform

      expect(booking.reload.status).to eq("cancelled")
      expect(booking.reload.cancelled_at).to be_present
    end

    it "does not cancel confirmed bookings when releasing expired slots" do
      slot = create(:slot, :held, held_until: 2.minutes.ago)
      booking = create(:booking, status: "confirmed")
      create(:booking_slot, booking: booking, slot: slot)

      described_class.new.perform

      expect(booking.reload.status).to eq("confirmed")
    end

    it "does not release non-expired held slots" do
      slot = create(:slot, :held, held_until: 10.minutes.from_now)

      described_class.new.perform

      expect(slot.reload.status).to eq("held")
    end

    it "does not affect open slots" do
      slot = create(:slot, status: "open")

      described_class.new.perform

      expect(slot.reload.status).to eq("open")
    end

    it "does not affect reserved slots" do
      slot = create(:slot, :reserved)

      described_class.new.perform

      expect(slot.reload.status).to eq("reserved")
    end
  end
end
