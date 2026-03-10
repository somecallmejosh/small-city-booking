require "rails_helper"

RSpec.describe PromoCode, type: :model do
  describe "validations" do
    subject(:promo_code) { build(:promo_code) }

    it "is valid with all required fields" do
      expect(promo_code).to be_valid
    end

    it "requires name" do
      promo_code.name = nil
      expect(promo_code).not_to be_valid
      expect(promo_code.errors[:name]).to be_present
    end

    it "requires code" do
      promo_code.code = nil
      expect(promo_code).not_to be_valid
      expect(promo_code.errors[:code]).to be_present
    end

    it "requires discount_percent" do
      promo_code.discount_percent = nil
      expect(promo_code).not_to be_valid
      expect(promo_code.errors[:discount_percent]).to be_present
    end

    it "requires start_date" do
      promo_code.start_date = nil
      expect(promo_code).not_to be_valid
    end

    it "requires end_date" do
      promo_code.end_date = nil
      expect(promo_code).not_to be_valid
    end

    it "rejects discount_percent of 0" do
      promo_code.discount_percent = 0
      expect(promo_code).not_to be_valid
    end

    it "accepts discount_percent of 1" do
      promo_code.discount_percent = 1
      expect(promo_code).to be_valid
    end

    it "accepts discount_percent of 100" do
      promo_code.discount_percent = 100
      expect(promo_code).to be_valid
    end

    it "rejects discount_percent of 101" do
      promo_code.discount_percent = 101
      expect(promo_code).not_to be_valid
    end

    it "rejects end_date before start_date" do
      promo_code.start_date = Date.current
      promo_code.end_date   = Date.current - 1.day
      expect(promo_code).not_to be_valid
      expect(promo_code.errors[:end_date]).to be_present
    end

    it "accepts end_date equal to start_date" do
      promo_code.start_date = Date.current
      promo_code.end_date   = Date.current
      expect(promo_code).to be_valid
    end

    it "enforces uniqueness of code (case-insensitive)" do
      create(:promo_code, code: "summer10")
      duplicate = build(:promo_code, code: "SUMMER10")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:code]).to be_present
    end
  end

  describe "code normalization" do
    it "downcases and strips the code before validation" do
      promo_code = build(:promo_code, code: "  SUMMER10  ")
      promo_code.valid?
      expect(promo_code.code).to eq("summer10")
    end
  end

  describe ".find_by_code" do
    it "finds a code case-insensitively" do
      promo = create(:promo_code, code: "holiday")
      expect(PromoCode.find_by_code("HOLIDAY")).to eq(promo)
      expect(PromoCode.find_by_code("holiday")).to eq(promo)
    end

    it "returns nil for blank input" do
      expect(PromoCode.find_by_code("")).to be_nil
      expect(PromoCode.find_by_code(nil)).to be_nil
    end
  end

  describe "#eligible_for?" do
    let(:user)  { create(:user) }
    let(:promo) { create(:promo_code, start_date: Date.current - 3.days, end_date: Date.current + 3.days) }

    def slot_at(time)
      build_stubbed(:slot, starts_at: time)
    end

    it "returns false when inactive" do
      promo.update!(active: false)
      slot = slot_at(Time.current)
      expect(promo.eligible_for?(user, [ slot ])).to be false
    end

    it "returns false when already used by this user" do
      booking = create(:booking, user: user)
      create(:promo_code_usage, promo_code: promo, user: user, booking: booking)
      slot = slot_at(Time.current)
      expect(promo.eligible_for?(user, [ slot ])).to be false
    end

    it "returns true when a slot starts within the window" do
      slot = slot_at(Time.current)
      expect(promo.eligible_for?(user, [ slot ])).to be true
    end

    it "returns false when no slots fall within the window" do
      slot = slot_at(Date.current + 10.days)
      expect(promo.eligible_for?(user, [ slot ])).to be false
    end

    it "returns true when at least one of multiple slots is in window" do
      slot_in     = slot_at(Time.current)
      slot_out    = slot_at(Date.current + 10.days)
      expect(promo.eligible_for?(user, [ slot_out, slot_in ])).to be true
    end

    context "with ET timezone boundary" do
      let(:et_zone) { ActiveSupport::TimeZone["Eastern Time (US & Canada)"] }

      it "returns false when slot starts on the day before start_date in ET" do
        # Slot starts at 11:59 PM ET the day before promo starts
        day_before_promo = promo.start_date - 1.day
        slot_time = et_zone.local(day_before_promo.year, day_before_promo.month, day_before_promo.day, 23, 59, 0)
        slot = slot_at(slot_time.utc)
        expect(promo.eligible_for?(user, [ slot ])).to be false
      end

      it "returns true when slot starts at midnight (00:00) ET on start_date" do
        slot_time = et_zone.local(promo.start_date.year, promo.start_date.month, promo.start_date.day, 0, 0, 0)
        slot = slot_at(slot_time.utc)
        expect(promo.eligible_for?(user, [ slot ])).to be true
      end

      it "returns true when slot starts at 23:59 ET on end_date" do
        slot_time = et_zone.local(promo.end_date.year, promo.end_date.month, promo.end_date.day, 23, 59, 0)
        slot = slot_at(slot_time.utc)
        expect(promo.eligible_for?(user, [ slot ])).to be true
      end
    end
  end

  describe "#discount_for" do
    let(:promo) { build_stubbed(:promo_code, discount_percent: 20) }

    it "calculates 20% of 5000 cents correctly" do
      expect(promo.discount_for(5000)).to eq(1000)
    end

    it "floors fractional cents" do
      # 10% of 5001 = 500.1 → floors to 500
      promo_10 = build_stubbed(:promo_code, discount_percent: 10)
      expect(promo_10.discount_for(5001)).to eq(500)
    end

    it "returns full amount for 100% discount" do
      promo_100 = build_stubbed(:promo_code, discount_percent: 100)
      expect(promo_100.discount_for(5000)).to eq(5000)
    end
  end

  describe "destroy protection" do
    let(:promo) { create(:promo_code) }

    it "can be destroyed when no usages exist" do
      promo # trigger creation before measuring
      expect { promo.destroy }.to change(PromoCode, :count).by(-1)
    end

    it "cannot be destroyed when usages exist" do
      booking = create(:booking)
      create(:promo_code_usage, promo_code: promo, user: booking.user, booking: booking)
      expect { promo.destroy }.not_to change(PromoCode, :count)
      expect(promo.errors[:base]).to be_present
    end
  end
end
