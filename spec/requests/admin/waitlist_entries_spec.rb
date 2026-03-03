require "rails_helper"

RSpec.describe "Admin::WaitlistEntries", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:customer) { create(:user) }

  def sign_in(u = admin)
    post session_path, params: { email_address: u.email_address, password: "securepassword1" }
  end

  describe "GET /admin/waitlist_entries" do
    before { sign_in }

    it "returns 200" do
      get admin_waitlist_entries_path
      expect(response).to have_http_status(:ok)
    end

    it "lists waitlist entries" do
      entry = create(:waitlist_entry, user: customer)
      get admin_waitlist_entries_path
      expect(response.body).to include(customer.email_address)
    end

    context "when not an admin" do
      before { sign_in(customer) }

      it "redirects to root" do
        get admin_waitlist_entries_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /admin/waitlist_entries/:id" do
    before { sign_in }

    it "destroys the entry and redirects with notice" do
      entry = create(:waitlist_entry, user: customer)

      expect { delete admin_waitlist_entry_path(entry) }
        .to change(WaitlistEntry, :count).by(-1)

      expect(response).to redirect_to(admin_waitlist_entries_path)
      follow_redirect!
      expect(response.body).to match(/removed/i)
    end

    context "when not an admin" do
      before { sign_in(customer) }

      it "redirects to root" do
        entry = create(:waitlist_entry, user: customer)
        delete admin_waitlist_entry_path(entry)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
