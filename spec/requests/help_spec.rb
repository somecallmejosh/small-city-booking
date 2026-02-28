require "rails_helper"

RSpec.describe "Help", type: :request do
  describe "GET /help" do
    it "is accessible without signing in" do
      get help_path
      expect(response).to have_http_status(:ok)
    end

    it "includes the booking calendar section" do
      get help_path
      expect(response.body).to include("Booking Calendar")
    end

    it "includes the checkout and hold section" do
      get help_path
      expect(response.body).to include("Checkout")
    end

    it "includes the cancellation policy section" do
      get help_path
      expect(response.body).to include("Cancellation")
    end

    it "includes the terms of booking section" do
      get help_path
      expect(response.body).to include("Terms of Booking")
    end

    it "does not show the admin workflow section to guests" do
      get help_path
      expect(response.body).not_to include("Admin Workflow")
    end

    context "when signed in as an admin" do
      let(:admin) { create(:user, :admin) }

      before do
        post session_path, params: { email_address: admin.email_address, password: "securepassword1" }
      end

      it "shows the admin workflow section" do
        get help_path
        expect(response.body).to include("Admin Workflow")
      end
    end
  end
end
