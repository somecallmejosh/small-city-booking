require "rails_helper"

RSpec.describe "Admin::Customers", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:customer) { create(:user, name: "Jane Smith", email_address: "jane@example.com") }

  def sign_in(u = admin)
    post session_path, params: { email_address: u.email_address, password: "securepassword1" }
  end

  describe "GET /admin/customers" do
    before { sign_in }

    it "returns 200" do
      get admin_customers_path
      expect(response).to have_http_status(:ok)
    end

    it "lists non-admin customers" do
      customer
      get admin_customers_path
      expect(response.body).to include("jane@example.com")
    end

    it "does not list admin users" do
      get admin_customers_path
      expect(response.body).not_to include(admin.email_address)
    end

    it "filters by name" do
      customer
      other = create(:user, name: "Bob Jones", email_address: "bob@example.com")
      get admin_customers_path(q: "Jane")
      expect(response.body).to include("jane@example.com")
      expect(response.body).not_to include(other.email_address)
    end

    it "filters by email" do
      customer
      other = create(:user, email_address: "other@example.com")
      get admin_customers_path(q: "jane@")
      expect(response.body).to include("jane@example.com")
      expect(response.body).not_to include(other.email_address)
    end

    context "when not an admin" do
      before { sign_in(customer) }

      it "redirects to root" do
        get admin_customers_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/customers/:id" do
    let(:agreement) { create(:agreement) }
    let(:slot)      { create(:slot, :reserved, starts_at: 2.days.from_now.beginning_of_hour) }
    let(:booking) do
      b = create(:booking, user: customer, agreement: agreement, status: "confirmed", total_cents: 10_000)
      b.slots << slot
      b
    end

    before do
      sign_in
      booking
    end

    it "returns 200" do
      get admin_customer_path(customer)
      expect(response).to have_http_status(:ok)
    end

    it "shows customer profile" do
      get admin_customer_path(customer)
      expect(response.body).to include("jane@example.com")
      expect(response.body).to include("Jane Smith")
    end

    it "shows booking history" do
      get admin_customer_path(customer)
      expect(response.body).to include("$100.00")
    end

    it "shows total spend" do
      get admin_customer_path(customer)
      expect(response.body).to include("$100.00")
    end

    it "returns 404 for admin users" do
      get admin_customer_path(admin)
      expect(response).to have_http_status(:not_found)
    end

    context "when not an admin" do
      before { sign_in(customer) }

      it "redirects to root" do
        get admin_customer_path(customer)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/customers/:id/edit" do
    before { sign_in }

    it "returns 200" do
      get edit_admin_customer_path(customer)
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for admin users" do
      get edit_admin_customer_path(admin)
      expect(response).to have_http_status(:not_found)
    end

    context "when not an admin" do
      before { sign_in(customer) }

      it "redirects to root" do
        get edit_admin_customer_path(customer)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /admin/customers/:id" do
    before { sign_in }

    it "updates name and phone and redirects to show" do
      patch admin_customer_path(customer), params: { user: { name: "Jane Updated", phone: "555-1234" } }
      expect(customer.reload.name).to eq("Jane Updated")
      expect(customer.reload.phone).to eq("555-1234")
      expect(response).to redirect_to(admin_customer_path(customer))
    end

    it "does not allow updating email or admin flag" do
      original_email = customer.email_address
      patch admin_customer_path(customer), params: { user: { email_address: "hacked@evil.com", admin: true } }
      expect(customer.reload.email_address).to eq(original_email)
      expect(customer.reload.admin).to be false
    end

    it "returns 404 for admin users" do
      patch admin_customer_path(admin), params: { user: { name: "X" } }
      expect(response).to have_http_status(:not_found)
    end

    context "when not an admin" do
      before { sign_in(customer) }

      it "redirects to root" do
        patch admin_customer_path(customer), params: { user: { name: "X" } }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
