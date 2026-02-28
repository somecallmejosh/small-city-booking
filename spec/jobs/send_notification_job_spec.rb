require "rails_helper"

RSpec.describe SendNotificationJob, type: :job do
  let(:user) { create(:user) }
  let(:invalid_subscription_error) do
    WebPush::InvalidSubscription.new(double("response", body: "gone", inspect: "410 Gone"), "push.example.com")
  end

  before do
    allow(WebPush).to receive(:payload_send)
  end

  describe "#perform" do
    it "sends a push notification to each of the user's subscriptions" do
      sub1 = create(:push_subscription, user: user)
      sub2 = create(:push_subscription, user: user)

      described_class.new.perform(user.id, "Hello", "Test body", url: "/bookings/1")

      expect(WebPush).to have_received(:payload_send).twice
      expect(WebPush).to have_received(:payload_send).with(
        hash_including(endpoint: sub1.endpoint, p256dh: sub1.p256dh, auth: sub1.auth)
      )
      expect(WebPush).to have_received(:payload_send).with(
        hash_including(endpoint: sub2.endpoint, p256dh: sub2.p256dh, auth: sub2.auth)
      )
    end

    it "sends the correct payload structure" do
      create(:push_subscription, user: user)

      described_class.new.perform(user.id, "My Title", "My body", url: "/bookings/99")

      expected_payload = { title: "My Title", options: { body: "My body", data: { path: "/bookings/99" } } }.to_json
      expect(WebPush).to have_received(:payload_send).with(
        hash_including(message: expected_payload)
      )
    end

    it "includes VAPID credentials" do
      create(:push_subscription, user: user)

      described_class.new.perform(user.id, "Title", "Body")

      expect(WebPush).to have_received(:payload_send).with(
        hash_including(
          vapid: hash_including(
            public_key:  ENV["VAPID_PUBLIC_KEY"],
            private_key: ENV["VAPID_PRIVATE_KEY"]
          )
        )
      )
    end

    it "destroys a stale subscription when InvalidSubscription is raised" do
      sub = create(:push_subscription, user: user)
      allow(WebPush).to receive(:payload_send).and_raise(invalid_subscription_error)

      expect {
        described_class.new.perform(user.id, "Title", "Body")
      }.to change(PushSubscription, :count).by(-1)

      expect(PushSubscription.find_by(id: sub.id)).to be_nil
    end

    it "continues sending to other subscriptions after a stale one is removed" do
      stale = create(:push_subscription, user: user)
      good  = create(:push_subscription, user: user)

      allow(WebPush).to receive(:payload_send).with(hash_including(endpoint: stale.endpoint))
                                               .and_raise(invalid_subscription_error)
      allow(WebPush).to receive(:payload_send).with(hash_including(endpoint: good.endpoint))

      described_class.new.perform(user.id, "Title", "Body")

      expect(PushSubscription.find_by(id: stale.id)).to be_nil
      expect(PushSubscription.find_by(id: good.id)).to be_present
      expect(WebPush).to have_received(:payload_send).with(hash_including(endpoint: good.endpoint))
    end

    it "does nothing when the user does not exist" do
      described_class.new.perform(0, "Title", "Body")

      expect(WebPush).not_to have_received(:payload_send)
    end

    it "does nothing when the user has no push subscriptions" do
      described_class.new.perform(user.id, "Title", "Body")

      expect(WebPush).not_to have_received(:payload_send)
    end
  end
end
