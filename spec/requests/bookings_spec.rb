require "rails_helper"

RSpec.describe "Bookings", type: :request do
  let(:user)      { create(:user) }
  let(:agreement) { create(:agreement) }
  let(:slot)      { create(:slot, status: "open") }

  def sign_in(u = user)
    post session_path, params: { email_address: u.email_address, password: "securepassword1" }
  end

  def hold_slot(s = slot)
    post slot_holds_path, params: { slot_ids: [ s.id ] }
    Booking.last
  end

  # Stub a successful Stripe::Checkout::Session.create call
  def stub_stripe_checkout(url: "https://checkout.stripe.com/pay/cs_test_fake")
    stub_request(:post, "https://api.stripe.com/v1/checkout/sessions")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: JSON.generate({
          id:     "cs_test_fake_#{SecureRandom.hex(4)}",
          object: "checkout.session",
          url:    url
        })
      )
  end

  def stub_stripe_refund(payment_intent_id: "pi_test_fake")
    stub_request(:post, "https://api.stripe.com/v1/refunds")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: JSON.generate({
          id:              "re_test_fake",
          object:          "refund",
          payment_intent:  payment_intent_id,
          status:          "succeeded"
        })
      )
  end

  describe "GET /bookings" do
    before { sign_in }

    it "returns 200" do
      get bookings_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /bookings/new" do
    context "when authenticated with a pending booking in session" do
      before do
        sign_in
        agreement # ensure agreement exists
        hold_slot
      end

      it "returns 200" do
        get new_booking_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when no pending booking in session" do
      before { sign_in }

      it "redirects to root with alert" do
        get new_booking_path
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to match(/hold has expired/i)
      end
    end
  end

  describe "POST /bookings" do
    let(:checkout_url) { "https://checkout.stripe.com/pay/cs_test_booking_#{SecureRandom.hex(4)}" }

    before do
      sign_in
      agreement
      hold_slot
    end

    it "creates a Stripe Checkout Session and redirects to Stripe" do
      stub_stripe_checkout(url: checkout_url)

      post bookings_path

      expect(response).to redirect_to(checkout_url)
    end

    it "stores the Stripe session ID on the booking" do
      stub_stripe_checkout

      post bookings_path

      booking = Booking.last
      expect(booking.stripe_payment_link_id).to be_present
    end
  end

  describe "GET /bookings/:id" do
    let(:booking) { create(:booking, user: user, status: "confirmed") }

    before { sign_in }

    it "returns 200 for confirmed booking" do
      slot = create(:slot, :reserved)
      booking.slots << slot

      get booking_path(booking)
      expect(response).to have_http_status(:ok)
    end

    it "shows processing state for pending booking" do
      pending_booking = create(:booking, user: user, status: "pending")
      pending_booking.slots << create(:slot, :held, held_by_user: user)

      get booking_path(pending_booking)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Payment processing")
    end
  end

  describe "POST /bookings/:id/cancel" do
    let(:reserved_slot) { create(:slot, :reserved, starts_at: 48.hours.from_now.beginning_of_hour) }
    let(:booking) do
      b = create(:booking, user: user, status: "confirmed",
                 stripe_payment_intent_id: "pi_test_fake")
      b.slots << reserved_slot
      b
    end

    before do
      sign_in
      StudioSetting.current.update!(cancellation_hours: 24)
    end

    context "when within cancellation window" do
      it "issues a refund, cancels the booking, and releases the slot" do
        stub_stripe_refund(payment_intent_id: "pi_test_fake")

        post cancel_booking_path(booking)

        expect(booking.reload.status).to eq("cancelled")
        expect(booking.reload.refunded).to be true
        expect(reserved_slot.reload.status).to eq("open")
        expect(response).to redirect_to(bookings_path)
      end

      it "enqueues a cancellation notification to the customer" do
        stub_stripe_refund(payment_intent_id: "pi_test_fake")

        post cancel_booking_path(booking)

        expect(SendNotificationJob).to have_been_enqueued.with(
          user.id, "Booking Cancelled", anything
        )
      end
    end

    context "when outside cancellation window" do
      let(:soon_slot) { create(:slot, :reserved, starts_at: 12.hours.from_now.beginning_of_hour) }
      let(:outside_booking) do
        b = create(:booking, user: user, status: "confirmed",
                   stripe_payment_intent_id: "pi_test_fake")
        b.slots << soon_slot
        b
      end

      it "cancels without issuing a refund" do
        post cancel_booking_path(outside_booking)

        expect(outside_booking.reload.status).to eq("cancelled")
        expect(outside_booking.reload.refunded).to be false
      end
    end

    context "when booking is not confirmed" do
      let(:cancelled_booking) { create(:booking, user: user, status: "cancelled") }

      it "redirects with alert" do
        post cancel_booking_path(cancelled_booking)
        expect(response).to redirect_to(booking_path(cancelled_booking))
        follow_redirect!
        expect(response.body).to match(/only confirmed/i)
      end
    end
  end
end
