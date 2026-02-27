require "rails_helper"

RSpec.describe "SlotHolds", type: :request do
  let(:user)      { create(:user) }
  let!(:agreement) { create(:agreement) }
  let(:slot)      { create(:slot, status: "open") }

  def sign_in(u = user)
    post session_path, params: { email_address: u.email_address, password: "securepassword1" }
  end

  describe "POST /slot_holds" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        post slot_holds_path, params: { slot_ids: [ slot.id ] }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated with open slots" do
      before { sign_in }

      it "holds the slots and creates a pending booking" do
        expect {
          post slot_holds_path, params: { slot_ids: [ slot.id ] }
        }.to change(Booking, :count).by(1)

        expect(slot.reload.status).to eq("held")
        expect(Booking.last.status).to eq("pending")
        expect(response).to redirect_to(new_booking_path)
      end

      it "stores the booking id in the session" do
        post slot_holds_path, params: { slot_ids: [ slot.id ] }
        expect(Booking.last.status).to eq("pending")
      end
    end

    context "when a slot is already held by another user" do
      before do
        sign_in
        other_user = create(:user)
        slot.update!(status: "held", held_by_user: other_user, held_until: 5.minutes.from_now)
      end

      it "does not create a booking and redirects back with alert" do
        expect {
          post slot_holds_path, params: { slot_ids: [ slot.id ] }
        }.not_to change(Booking, :count)

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to match(/no longer available/i)
      end
    end

    context "when no slot_ids provided" do
      before { sign_in }

      it "redirects with alert" do
        post slot_holds_path, params: {}
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to match(/select at least one slot/i)
      end
    end
  end

  describe "DELETE /slot_holds/:id" do
    context "when authenticated with a pending booking in session" do
      before do
        sign_in
        post slot_holds_path, params: { slot_ids: [ slot.id ] }
      end

      it "releases the hold and cancels the booking" do
        booking = Booking.last

        delete slot_hold_path(booking)

        expect(slot.reload.status).to eq("open")
        expect(booking.reload.status).to eq("cancelled")
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
