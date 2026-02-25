require "rails_helper"

RSpec.describe Agreement, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      agreement = build(:agreement)
      expect(agreement).to be_valid
    end

    it "auto-assigns a version number before create" do
      agreement = create(:agreement)
      expect(agreement.version).to eq(1)
    end

    it "auto-increments the version for each new agreement" do
      create(:agreement)
      second = create(:agreement)
      expect(second.version).to eq(2)
    end

    it "version numbers are unique across records" do
      first  = create(:agreement)
      second = create(:agreement)
      expect(first.version).not_to eq(second.version)
    end
  end

  describe ".current" do
    it "returns the most recently published agreement" do
      old_agreement = create(:agreement, published_at: 2.days.ago)
      new_agreement = create(:agreement, published_at: 1.hour.ago)
      expect(Agreement.current).to eq(new_agreement)
    end

    it "returns nil when no published agreements exist" do
      create(:agreement, published_at: nil)
      expect(Agreement.current).to be_nil
    end
  end

  describe ".published scope" do
    it "excludes unpublished agreements" do
      published   = create(:agreement, published_at: Time.current)
      unpublished = create(:agreement, published_at: nil)
      expect(Agreement.published).to include(published)
      expect(Agreement.published).not_to include(unpublished)
    end
  end
end
