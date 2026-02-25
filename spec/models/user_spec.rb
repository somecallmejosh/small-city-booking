require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to be_valid }

    it "requires an email address" do
      user = build(:user, email_address: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to be_present
    end

    it "requires a unique email address (case-insensitive)" do
      create(:user, email_address: "alice@example.com")
      duplicate = build(:user, email_address: "ALICE@example.com")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email_address]).to be_present
    end

    it "strips and downcases the email address" do
      user = create(:user, email_address: "  Bob@EXAMPLE.COM  ")
      expect(user.email_address).to eq("bob@example.com")
    end

    it "requires a password of at least 12 characters on new record" do
      user = build(:user, password: "short")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "accepts a password of exactly 12 characters" do
      user = build(:user, password: "a" * 12)
      expect(user).to be_valid
    end

    it "does not re-validate password length when updating other fields" do
      user = create(:user)
      user.name = "New Name"
      expect(user).to be_valid
    end
  end

  describe "associations" do
    it "has many sessions" do
      assoc = User.reflect_on_association(:sessions)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end

    it "has many bookings" do
      assoc = User.reflect_on_association(:bookings)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end

    it "has many push_subscriptions" do
      assoc = User.reflect_on_association(:push_subscriptions)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end

    it "has many held_slots" do
      assoc = User.reflect_on_association(:held_slots)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:nullify)
    end
  end

  describe "#admin" do
    it "defaults to false" do
      user = create(:user)
      expect(user.admin).to be false
    end

    it "can be set to true" do
      user = create(:user, :admin)
      expect(user.admin).to be true
    end
  end
end
