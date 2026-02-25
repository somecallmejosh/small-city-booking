require "rails_helper"

RSpec.describe PushSubscription, type: :model do
  it "is valid with valid attributes" do
    sub = build(:push_subscription)
    expect(sub).to be_valid
  end

  it "requires endpoint" do
    sub = build(:push_subscription, endpoint: nil)
    expect(sub).not_to be_valid
  end

  it "requires p256dh" do
    sub = build(:push_subscription, p256dh: nil)
    expect(sub).not_to be_valid
  end

  it "requires auth" do
    sub = build(:push_subscription, auth: nil)
    expect(sub).not_to be_valid
  end
end
