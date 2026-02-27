require "rails_helper"

RSpec.describe "Admin::Bookings", type: :request do
  let(:admin)     { create(:user, :admin) }
  let(:customer)  { create(:user) }
  let(:agreement) { create(:agreement) }

  def sign_in(u = admin)
    post session_path, params: { email_address: u.email_address, password: "securepassword1" }
  end

  def stub_stripe_refund(payment_intent_id: "pi_test_fake")
    stub_request(:post, "https://api.stripe.com/v1/refunds")
      .to_return(
        status:  200,
        headers: { "Content-Type" => "application/json" },
        body:    JSON.generate({
          id:             "re_test_fake",
          object:         "refund",
          payment_intent: payment_intent_id,
          status:         "succeeded"
        })
      )
  end

  describe "GET /admin/bookings" do
    before { sign_in }

    it "returns 200" do
      get admin_bookings_path
      expect(response).to have_http_status(:ok)
    end

    it "filters by status" do
      confirmed_customer = create(:user, email_address: "confirmed_customer@example.com")
      cancelled_customer = create(:user, email_address: "cancelled_customer@example.com")
      create(:booking, user: confirmed_customer, agreement: agreement, status: "confirmed")
      create(:booking, user: cancelled_customer, agreement: agreement, status: "cancelled")

      get admin_bookings_path(status: "confirmed")

      expect(response.body).to include("confirmed_customer@example.com")
      expect(response.body).not_to include("cancelled_customer@example.com")
    end

    context "when not an admin" do
      before { sign_in(customer) }

      it "redirects to root" do
        get admin_bookings_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/bookings/:id" do
    let(:booking) do
      b = create(:booking, user: customer, agreement: agreement, status: "confirmed")
      b.slots << create(:slot, :reserved)
      b
    end

    before { sign_in }

    it "returns 200" do
      get admin_booking_path(booking)
      expect(response).to have_http_status(:ok)
    end

    it "shows customer details" do
      get admin_booking_path(booking)
      expect(response.body).to include(customer.email_address)
    end
  end

  describe "POST /admin/bookings/:id/cancel" do
    before do
      sign_in
      StudioSetting.current.update!(cancellation_hours: 24)
    end

    context "within the cancellation window (≥24h away)" do
      let(:future_slot) { create(:slot, :reserved, starts_at: 48.hours.from_now.beginning_of_hour) }
      let(:booking) do
        b = create(:booking, user: customer, agreement: agreement, status: "confirmed",
                   stripe_payment_intent_id: "pi_test_fake")
        b.slots << future_slot
        b
      end

      it "issues a refund, cancels the booking, and releases slots" do
        stub_stripe_refund(payment_intent_id: "pi_test_fake")

        post cancel_admin_booking_path(booking)

        expect(booking.reload.status).to eq("cancelled")
        expect(booking.reload.refunded).to be true
        expect(future_slot.reload.status).to eq("open")
        expect(response).to redirect_to(admin_bookings_path)
      end
    end

    context "outside the cancellation window (<24h away)" do
      let(:soon_slot) { create(:slot, :reserved, starts_at: 6.hours.from_now.beginning_of_hour) }
      let(:outside_booking) do
        b = create(:booking, user: customer, agreement: agreement, status: "confirmed",
                   stripe_payment_intent_id: "pi_test_fake")
        b.slots << soon_slot
        b
      end

      it "still issues a refund regardless of the cancellation window" do
        stub_stripe_refund(payment_intent_id: "pi_test_fake")

        post cancel_admin_booking_path(outside_booking)

        expect(outside_booking.reload.status).to eq("cancelled")
        expect(outside_booking.reload.refunded).to be true
      end
    end

    context "when booking has no payment intent (admin-created without payment)" do
      let(:no_payment_booking) do
        b = create(:booking, user: customer, agreement: agreement, status: "confirmed",
                   admin_created: true, total_cents: 0)
        b.slots << create(:slot, :reserved)
        b
      end

      it "cancels without attempting a refund" do
        post cancel_admin_booking_path(no_payment_booking)

        expect(no_payment_booking.reload.status).to eq("cancelled")
        expect(no_payment_booking.reload.refunded).to be false
      end
    end

    context "when booking is already cancelled" do
      let(:cancelled_booking) { create(:booking, user: customer, agreement: agreement, status: "cancelled") }

      it "redirects with alert" do
        post cancel_admin_booking_path(cancelled_booking)
        expect(response).to redirect_to(admin_booking_path(cancelled_booking))
      end
    end
  end

  describe "GET /admin/bookings/new" do
    before { sign_in }

    it "returns 200" do
      get new_admin_booking_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/bookings" do
    let(:open_slot) { create(:slot, starts_at: 2.days.from_now.beginning_of_hour) }

    before do
      sign_in
      agreement
      StudioSetting.current.update!(hourly_rate_cents: 5000)
    end

    it "creates a confirmed admin booking and reserves the slot" do
      post admin_bookings_path, params: {
        booking: {
          user_id:  customer.id,
          slot_ids: [ open_slot.id ],
          notes:    "Test note"
        }
      }

      created = Booking.last
      expect(created.status).to eq("confirmed")
      expect(created.admin_created).to be true
      expect(created.total_cents).to eq(5000)
      expect(created.notes).to eq("Test note")
      expect(open_slot.reload.status).to eq("reserved")
      expect(response).to redirect_to(admin_booking_path(created))
    end

    it "re-renders new on invalid input" do
      post admin_bookings_path, params: {
        booking: { user_id: "", slot_ids: [] }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    context "with generate_payment_link" do
      before do
        stub_request(:post, "https://api.stripe.com/v1/prices")
          .to_return(
            status:  200,
            headers: { "Content-Type" => "application/json" },
            body:    JSON.generate({ id: "price_test_fake", object: "price" })
          )
        stub_request(:post, "https://api.stripe.com/v1/payment_links")
          .to_return(
            status:  200,
            headers: { "Content-Type" => "application/json" },
            body:    JSON.generate({
              id:     "plink_test_fake",
              object: "payment_link",
              url:    "https://buy.stripe.com/test_link"
            })
          )
      end

      it "creates the booking and stores the Payment Link URL" do
        post admin_bookings_path, params: {
          booking: {
            user_id:               customer.id,
            slot_ids:              [ open_slot.id ],
            generate_payment_link: "1"
          }
        }

        created = Booking.last
        expect(created.stripe_payment_link_id).to eq("plink_test_fake")
        expect(created.stripe_payment_link_url).to eq("https://buy.stripe.com/test_link")
      end
    end
  end
end
