require "rails_helper"

RSpec.describe "PushSubscriptions", type: :request do
  let(:user) { create(:user) }

  def sign_in(u = user)
    post session_path, params: { email_address: u.email_address, password: "securepassword1" }
  end

  def subscription_params
    {
      endpoint: "https://push.example.com/#{SecureRandom.hex(8)}",
      p256dh:   SecureRandom.base64(32),
      auth:     SecureRandom.base64(16)
    }
  end

  describe "POST /push_subscriptions" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        post push_subscriptions_path,
             params: subscription_params.to_json,
             headers: { "Content-Type" => "application/json" }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in }

      it "creates a push subscription and returns the id" do
        params = subscription_params

        expect {
          post push_subscriptions_path,
               params: params.to_json,
               headers: { "Content-Type" => "application/json" }
        }.to change(PushSubscription, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["id"]).to eq(PushSubscription.last.id)
        expect(PushSubscription.last.endpoint).to eq(params[:endpoint])
        expect(PushSubscription.last.user).to eq(user)
      end

      it "does not create a duplicate for the same endpoint" do
        existing = create(:push_subscription, user: user)

        expect {
          post push_subscriptions_path,
               params: { endpoint: existing.endpoint, p256dh: existing.p256dh, auth: existing.auth }.to_json,
               headers: { "Content-Type" => "application/json" }
        }.not_to change(PushSubscription, :count)

        expect(response).to have_http_status(:created)
      end

      it "returns bad request for malformed JSON" do
        post push_subscriptions_path,
             params: "not-json",
             headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "DELETE /push_subscriptions/:id" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        sub = create(:push_subscription, user: user)
        delete push_subscription_path(sub)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in }

      it "destroys the user's own subscription" do
        sub = create(:push_subscription, user: user)

        expect {
          delete push_subscription_path(sub)
        }.to change(PushSubscription, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it "does not destroy another user's subscription" do
        other_user = create(:user)
        sub = create(:push_subscription, user: other_user)

        expect {
          delete push_subscription_path(sub)
        }.not_to change(PushSubscription, :count)

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
