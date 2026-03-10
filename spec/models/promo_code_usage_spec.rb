require "rails_helper"

RSpec.describe PromoCodeUsage, type: :model do
  describe "associations" do
    it "belongs to promo_code" do
      assoc = described_class.reflect_on_association(:promo_code)
      expect(assoc.macro).to eq(:belongs_to)
    end

    it "belongs to user" do
      assoc = described_class.reflect_on_association(:user)
      expect(assoc.macro).to eq(:belongs_to)
    end

    it "belongs to booking" do
      assoc = described_class.reflect_on_association(:booking)
      expect(assoc.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "prevents the same user from using the same promo code twice" do
      promo   = create(:promo_code)
      user    = create(:user)
      booking = create(:booking, user: user)
      create(:promo_code_usage, promo_code: promo, user: user, booking: booking)

      second_booking = create(:booking, user: user)
      duplicate = build(:promo_code_usage, promo_code: promo, user: user, booking: second_booking)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:promo_code_id]).to be_present
    end

    it "allows different users to use the same code" do
      promo    = create(:promo_code)
      user1    = create(:user)
      user2    = create(:user)
      booking1 = create(:booking, user: user1)
      booking2 = create(:booking, user: user2)

      create(:promo_code_usage, promo_code: promo, user: user1, booking: booking1)
      usage2 = build(:promo_code_usage, promo_code: promo, user: user2, booking: booking2)
      expect(usage2).to be_valid
    end
  end
end
