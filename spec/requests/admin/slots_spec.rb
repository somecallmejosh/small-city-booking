require "rails_helper"

RSpec.describe "Admin::Slots", type: :request do
  let(:admin) { create(:user, :admin) }

  before do
    post session_path, params: { email_address: admin.email_address, password: "securepassword1" }
  end

  describe "GET /admin/slots" do
    it "returns 200" do
      get admin_slots_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/slots/new" do
    it "returns 200" do
      get new_admin_slot_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/slots/bulk_new" do
    it "returns 200" do
      get bulk_new_admin_slots_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/slots" do
    context "with valid params" do
      it "creates a slot and redirects to index" do
        expect {
          post admin_slots_path, params: { slot: { starts_at: 1.day.from_now.beginning_of_hour } }
        }.to change(Slot, :count).by(1)

        expect(response).to redirect_to(admin_slots_path)
      end

      it "creates the slot with status open" do
        post admin_slots_path, params: { slot: { starts_at: 1.day.from_now.beginning_of_hour } }
        expect(Slot.last.status).to eq("open")
      end
    end

    context "with missing starts_at" do
      it "re-renders new with unprocessable status" do
        post admin_slots_path, params: { slot: { starts_at: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /admin/slots/bulk_create" do
    let(:monday) { Date.today.next_occurring(:monday) }

    it "creates slots and redirects with a flash notice" do
      expect {
        post bulk_create_admin_slots_path, params: {
          days_of_week: [ "1" ],
          start_date:   monday.to_s,
          end_date:     monday.to_s,
          start_hour:   "14",
          end_hour:     "16"
        }
      }.to change(Slot, :count).by(2)

      expect(response).to redirect_to(admin_slots_path)
      follow_redirect!
      expect(response.body).to include("Created 2 slot(s)")
    end
  end

  describe "DELETE /admin/slots/:id" do
    context "when the slot is open" do
      let(:slot) { create(:slot, status: "open") }

      it "sets status to cancelled and redirects" do
        delete admin_slot_path(slot)
        expect(slot.reload.status).to eq("cancelled")
        expect(response).to redirect_to(admin_slots_path)
      end
    end

    context "when the slot is reserved" do
      let(:slot) { create(:slot, :reserved) }

      it "does not change status and redirects with an alert" do
        delete admin_slot_path(slot)
        expect(slot.reload.status).to eq("reserved")
        expect(response).to redirect_to(admin_slots_path)
        follow_redirect!
        expect(response.body).to match(/cannot cancel/i)
      end
    end
  end

  describe "DELETE /admin/slots/bulk_destroy" do
    let!(:slot_a) { create(:slot, status: "open") }
    let!(:slot_b) { create(:slot, status: "open") }
    let!(:reserved_slot) { create(:slot, :reserved) }

    it "cancels the selected open slots and redirects with a notice" do
      expect {
        delete bulk_destroy_admin_slots_path, params: { slot_ids: [ slot_a.id, slot_b.id ] }
      }.not_to change(Slot, :count)

      expect(slot_a.reload.status).to eq("cancelled")
      expect(slot_b.reload.status).to eq("cancelled")
      expect(response).to redirect_to(admin_slots_path)
      follow_redirect!
      expect(response.body).to include("Cancelled 2 slot(s)")
    end

    it "ignores non-open slots even if their IDs are submitted" do
      delete bulk_destroy_admin_slots_path, params: { slot_ids: [ reserved_slot.id ] }
      expect(reserved_slot.reload.status).to eq("reserved")
    end

    it "handles an empty selection gracefully" do
      delete bulk_destroy_admin_slots_path, params: { slot_ids: [] }
      expect(response).to redirect_to(admin_slots_path)
    end
  end
end
