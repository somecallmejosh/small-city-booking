require "rails_helper"

RSpec.describe "Bookings", type: :request do
  let(:user)      { create(:user, :verified) }
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

  describe "POST /bookings/apply_promo" do
    let(:promo) { create(:promo_code, discount_percent: 20) }

    before do
      sign_in
      agreement
      hold_slot
    end

    context "with a valid promo code" do
      it "returns turbo stream, applies discount to booking" do
        post apply_promo_bookings_path,
             params: { promo_code: promo.code },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("turbo-stream")
        booking = Booking.pending.last
        expect(booking.discount_cents).to eq(promo.discount_for(booking.total_cents))
        expect(booking.promo_code).to eq(promo)
      end

      it "is case-insensitive" do
        post apply_promo_bookings_path,
             params: { promo_code: promo.code.upcase },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        booking = Booking.pending.last
        expect(booking.promo_code).to eq(promo)
      end
    end

    context "with an invalid code" do
      it "returns turbo stream with error, clears any previous promo" do
        post apply_promo_bookings_path,
             params: { promo_code: "BADCODE" },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        booking = Booking.pending.last
        expect(booking.promo_code).to be_nil
        expect(booking.discount_cents).to eq(0)
      end
    end

    context "with a code already used by this user" do
      before do
        used_booking = create(:booking, user: user)
        create(:promo_code_usage, promo_code: promo, user: user, booking: used_booking)
      end

      it "returns turbo stream with error" do
        post apply_promo_bookings_path,
             params: { promo_code: promo.code },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        booking = Booking.pending.last
        expect(booking.promo_code).to be_nil
      end
    end

    context "with a blank code (clears promo)" do
      before do
        Booking.pending.last.update!(promo_code: promo, discount_cents: 1000)
      end

      it "clears the promo code and resets discount to 0" do
        post apply_promo_bookings_path,
             params: { promo_code: "" },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        booking = Booking.pending.last
        expect(booking.promo_code).to be_nil
        expect(booking.discount_cents).to eq(0)
      end
    end

    context "when hold has expired" do
      it "redirects to root with alert" do
        booking = Booking.pending.last
        booking.slots.update_all(held_until: 1.minute.ago)

        post apply_promo_bookings_path, params: { promo_code: promo.code }

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /bookings with promo code" do
    let(:promo) { create(:promo_code, discount_percent: 20) }

    before do
      sign_in
      agreement
      hold_slot
      Booking.pending.last.update!(promo_code: promo, discount_cents: 1000)
    end

    it "passes charged_cents (not total_cents) to Stripe" do
      booking = Booking.pending.last
      charged = booking.charged_cents

      stub_stripe_checkout
      post bookings_path

      expect(a_request(:post, "https://api.stripe.com/v1/checkout/sessions")
        .with(body: /unit_amount.*#{charged}/)).to have_been_made
    end

    context "when promo becomes ineligible between apply and checkout" do
      before { promo.update!(active: false) }

      it "clears discount and redirects to new_booking_path with alert" do
        post bookings_path

        booking = Booking.pending.last
        expect(booking.promo_code).to be_nil
        expect(booking.discount_cents).to eq(0)
        expect(response).to redirect_to(new_booking_path)
      end
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

      it "enqueues NotifyWaitlistJob after releasing slots" do
        stub_stripe_refund(payment_intent_id: "pi_test_fake")

        post cancel_booking_path(booking)

        expect(NotifyWaitlistJob).to have_been_enqueued
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

    context "with a discounted booking within cancellation window" do
      let(:promo)    { create(:promo_code, discount_percent: 20) }
      let(:discounted_booking) do
        b = create(:booking, user: user, status: "confirmed",
                   stripe_payment_intent_id: "pi_test_fake",
                   total_cents: 8000, discount_cents: 1600,
                   promo_code: promo)
        b.slots << reserved_slot
        b
      end

      it "refunds charged_cents (not total_cents)" do
        refund_stub = stub_request(:post, "https://api.stripe.com/v1/refunds")
          .with(body: hash_including("amount" => "6400"))
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: JSON.generate({ id: "re_test_fake", object: "refund",
                                   payment_intent: "pi_test_fake", status: "succeeded" })
          )

        post cancel_booking_path(discounted_booking)

        expect(refund_stub).to have_been_requested
        expect(discounted_booking.reload.refunded).to be true
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
