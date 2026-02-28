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
      booking = build(:booking, status: "bogus")
      expect(booking).not_to be_valid
    end

    it "accepts pending as a valid status" do
      booking = build(:booking, status: "pending")
      expect(booking).to be_valid
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

    it ".pending returns only pending bookings" do
      pending_booking   = create(:booking, status: "pending")
      confirmed_booking = create(:booking, status: "confirmed")
      expect(Booking.pending).to include(pending_booking)
      expect(Booking.pending).not_to include(confirmed_booking)
    end
  end

  describe "#safe_receipt_url" do
    it "returns the URL when it is a valid https URL" do
      booking = build(:booking, stripe_receipt_url: "https://pay.stripe.com/receipts/test123")
      expect(booking.safe_receipt_url).to eq("https://pay.stripe.com/receipts/test123")
    end

    it "returns nil when stripe_receipt_url is blank" do
      booking = build(:booking, stripe_receipt_url: nil)
      expect(booking.safe_receipt_url).to be_nil
    end

    it "returns nil for a non-https URL" do
      booking = build(:booking, stripe_receipt_url: "http://pay.stripe.com/receipts/test123")
      expect(booking.safe_receipt_url).to be_nil
    end

    it "returns nil for a javascript: URI" do
      booking = build(:booking, stripe_receipt_url: "javascript:alert(1)")
      expect(booking.safe_receipt_url).to be_nil
    end
  end

  describe "#within_cancellation_window?" do
    let(:settings) { StudioSetting.current }

    before { settings.update!(cancellation_hours: 24) }

    it "returns true when the slot starts far in the future" do
      slot    = create(:slot, starts_at: 48.hours.from_now.beginning_of_hour)
      booking = create(:booking, status: "confirmed")
      booking.slots << slot
      expect(booking.within_cancellation_window?).to be true
    end

    it "returns false when the slot is within the cancellation window" do
      slot    = create(:slot, starts_at: 12.hours.from_now.beginning_of_hour)
      booking = create(:booking, status: "confirmed")
      booking.slots << slot
      expect(booking.within_cancellation_window?).to be false
    end

    it "returns false when the slot starts at exactly the boundary" do
      slot    = create(:slot, starts_at: 24.hours.from_now)
      booking = create(:booking, status: "confirmed")
      booking.slots << slot
      expect(booking.within_cancellation_window?).to be false
    end

    it "returns true when the slot starts one second past the boundary" do
      slot    = create(:slot, starts_at: 24.hours.from_now + 1.second)
      booking = create(:booking, status: "confirmed")
      booking.slots << slot
      expect(booking.within_cancellation_window?).to be true
    end
  end
end
