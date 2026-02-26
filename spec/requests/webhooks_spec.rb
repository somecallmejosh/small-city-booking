require "rails_helper"

RSpec.describe "Webhooks", type: :request do
  let(:user)      { create(:user) }
  let(:agreement) { create(:agreement) }
  let(:slot)      { create(:slot, :held, held_by_user: user, held_until: 5.minutes.from_now) }
  let(:booking) do
    b = create(:booking, user: user, agreement: agreement, status: "pending", total_cents: 5000)
    BookingSlot.create!(booking: b, slot: slot)
    b
  end

  def post_webhook(type:, data:)
    envelope = stripe_webhook_payload(type: type, data: data)
    post webhooks_stripe_path,
         params:  envelope[:payload],
         headers: {
           "Content-Type"     => "application/json",
           "HTTP_STRIPE_SIGNATURE" => envelope[:sig_header]
         }
  end

  describe "POST /webhooks/stripe" do
    context "with a bad signature" do
      it "returns 400" do
        post webhooks_stripe_path,
             params:  "{}",
             headers: {
               "Content-Type"     => "application/json",
               "HTTP_STRIPE_SIGNATURE" => "t=1,v1=badsig"
             }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "payment_intent.succeeded" do
      let(:intent_data) do
        {
          "id"       => "pi_test_success",
          "object"   => "payment_intent",
          "metadata" => {
            "booking_id"       => booking.id.to_s,
            "agreement_id"     => agreement.id.to_s,
            "agreed_ip"        => "127.0.0.1",
            "agreed_user_agent" => "TestAgent/1.0"
          }
        }
      end

      it "confirms the booking, reserves slots, and creates an AgreementAcceptance" do
        expect {
          post_webhook(type: "payment_intent.succeeded", data: intent_data)
        }.to change(AgreementAcceptance, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(booking.reload.status).to eq("confirmed")
        expect(slot.reload.status).to eq("reserved")
        expect(AgreementAcceptance.last.booking).to eq(booking)
      end

      it "is idempotent (second call does not create another AgreementAcceptance)" do
        post_webhook(type: "payment_intent.succeeded", data: intent_data)

        expect {
          post_webhook(type: "payment_intent.succeeded", data: intent_data)
        }.not_to change(AgreementAcceptance, :count)
      end
    end

    context "payment_intent.payment_failed" do
      let(:intent_data) do
        {
          "id"       => "pi_test_failed",
          "object"   => "payment_intent",
          "metadata" => { "booking_id" => booking.id.to_s }
        }
      end

      it "cancels the booking and releases the slots" do
        post_webhook(type: "payment_intent.payment_failed", data: intent_data)

        expect(response).to have_http_status(:ok)
        expect(booking.reload.status).to eq("cancelled")
        expect(slot.reload.status).to eq("open")
      end
    end

    context "unrecognized event type" do
      it "returns 200 and is a no-op" do
        post_webhook(type: "customer.created", data: { "id" => "cus_test" })
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
