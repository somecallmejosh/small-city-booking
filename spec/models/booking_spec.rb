require "rails_helper"

RSpec.describe Booking, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      booking = build(:booking)
      expect(booking).to be_valid
    end

    it "requires total_cents" do
      booking = build(:booking, total_cents: nil)
      expect(booking).not_to be_valid
    end

    it "allows total_cents of 0 (admin-created with no payment)" do
      booking = build(:booking, total_cents: 0)
      expect(booking).to be_valid
    end

    it "rejects an invalid status" do
      booking = build(:booking, status: "pending")
      expect(booking).not_to be_valid
    end

    it "accepts all valid statuses" do
      Booking::STATUSES.each do |status|
        booking = build(:booking, status: status)
        expect(booking).to be_valid, "expected #{status} to be valid"
      end
    end
  end

  describe "scopes" do
    it ".confirmed returns only confirmed bookings" do
      confirmed  = create(:booking, status: "confirmed")
      cancelled  = create(:booking, status: "cancelled")
      expect(Booking.confirmed).to include(confirmed)
      expect(Booking.confirmed).not_to include(cancelled)
    end

    it ".cancelled returns only cancelled bookings" do
      cancelled  = create(:booking, status: "cancelled")
      confirmed  = create(:booking, status: "confirmed")
      expect(Booking.cancelled).to include(cancelled)
      expect(Booking.cancelled).not_to include(confirmed)
    end
  end
end
