require "rails_helper"

RSpec.describe "Admin::Docs", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:customer) { create(:user) }

  def sign_in(u = admin)
    post session_path, params: { email_address: u.email_address, password: "securepassword1" }
  end

  admin_doc_paths = %w[
    /admin/docs
    /admin/docs/slots
    /admin/docs/bookings
    /admin/docs/customers
    /admin/docs/agreement
    /admin/docs/settings
    /admin/docs/tips
  ]

  admin_doc_paths.each do |path|
    describe "GET #{path}" do
      context "when signed in as admin" do
        before { sign_in }

        it "returns 200" do
          get path
          expect(response).to have_http_status(:ok)
        end
      end

      context "when not signed in" do
        it "redirects" do
          get path
          expect(response).to have_http_status(:redirect)
        end
      end

      context "when signed in as a non-admin customer" do
        before { sign_in(customer) }

        it "redirects to root" do
          get path
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end

  describe "GET /admin/docs" do
    before { sign_in }

    it "includes a link to the customer help section" do
      get admin_docs_path
      expect(response.body).to include(help_path)
    end
  end

  describe "GET /admin/docs/slots" do
    before { sign_in }

    it "includes slot management content" do
      get admin_docs_slots_path
      expect(response.body).to include("Bulk Create")
    end
  end

  describe "GET /admin/docs/bookings" do
    before { sign_in }

    it "includes booking status descriptions" do
      get admin_docs_bookings_path
      expect(response.body).to include("Confirmed")
      expect(response.body).to include("Cancelled")
    end
  end
end
