require "rails_helper"

RSpec.describe StudioSetting, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      setting = build(:studio_setting)
      expect(setting).to be_valid
    end

    it "requires hourly_rate_cents" do
      setting = build(:studio_setting, hourly_rate_cents: nil)
      expect(setting).not_to be_valid
    end

    it "requires hourly_rate_cents to be greater than 0" do
      setting = build(:studio_setting, hourly_rate_cents: 0)
      expect(setting).not_to be_valid
    end

    it "requires cancellation_hours" do
      setting = build(:studio_setting, cancellation_hours: nil)
      expect(setting).not_to be_valid
    end

    it "allows cancellation_hours of 0" do
      setting = build(:studio_setting, cancellation_hours: 0)
      expect(setting).to be_valid
    end
  end

  describe ".current" do
    it "returns the first record or creates one" do
      setting = StudioSetting.current
      expect(setting).to be_persisted
      expect(setting.hourly_rate_cents).to be > 0
    end

    it "returns the same record on subsequent calls" do
      first  = StudioSetting.current
      second = StudioSetting.current
      expect(first.id).to eq(second.id)
    end
  end
end
