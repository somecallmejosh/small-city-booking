require "rails_helper"

RSpec.describe Slot, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      slot = build(:slot)
      expect(slot).to be_valid
    end

    it "requires starts_at" do
      slot = build(:slot, starts_at: nil)
      expect(slot).not_to be_valid
    end

    it "rejects an invalid status" do
      slot = build(:slot, status: "bogus")
      expect(slot).not_to be_valid
    end

    it "accepts all valid statuses" do
      Slot::STATUSES.each do |status|
        slot = build(:slot, status: status)
        expect(slot).to be_valid, "expected #{status} to be valid"
      end
    end
  end

  describe "#ends_at" do
    it "is exactly 1 hour after starts_at" do
      slot = build(:slot, starts_at: Time.zone.parse("2026-03-01 15:00:00"))
      expect(slot.ends_at).to eq(Time.zone.parse("2026-03-01 16:00:00"))
    end
  end

  describe ".available scope" do
    it "includes open slots" do
      slot = create(:slot, status: "open")
      expect(Slot.available).to include(slot)
    end

    it "excludes reserved slots" do
      slot = create(:slot, :reserved)
      expect(Slot.available).not_to include(slot)
    end

    it "excludes held slots with a future held_until" do
      slot = create(:slot, :held)
      expect(Slot.available).not_to include(slot)
    end

    it "includes held slots whose hold has expired (lazy cleanup)" do
      slot = create(:slot, status: "held", held_until: 1.minute.ago, held_by_user: create(:user))
      expect(Slot.available).to include(slot)
    end
  end
end
