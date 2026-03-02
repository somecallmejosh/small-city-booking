require "rails_helper"

RSpec.describe "Help", type: :request do
  describe "GET /help" do
    it "is accessible without signing in" do
      get help_path
      expect(response).to have_http_status(:ok)
    end

    it "links to each topic" do
      get help_path
      expect(response.body).to include("Booking Calendar")
      expect(response.body).to include("Checkout")
      expect(response.body).to include("Cancellations")
      expect(response.body).to include("Terms of Booking")
    end

    it "does not contain admin workflow content" do
      get help_path
      expect(response.body).not_to include("Admin Workflow")
    end
  end

  describe "GET /help/getting-started" do
    it "is accessible without signing in" do
      get help_getting_started_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /help/calendar" do
    it "is accessible without signing in" do
      get help_calendar_path
      expect(response).to have_http_status(:ok)
    end

    it "includes slot color descriptions" do
      get help_calendar_path
      expect(response.body).to include("Open")
      expect(response.body).to include("Held")
      expect(response.body).to include("Reserved")
    end
  end

  describe "GET /help/checkout" do
    it "is accessible without signing in" do
      get help_checkout_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /help/cancellations" do
    it "is accessible without signing in" do
      get help_cancellations_path
      expect(response).to have_http_status(:ok)
    end

    it "describes the refund policy" do
      get help_cancellations_path
      expect(response.body).to include("24 hours")
    end
  end

  describe "GET /help/notifications" do
    it "is accessible without signing in" do
      get help_notifications_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /help/account" do
    it "is accessible without signing in" do
      get help_account_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /help/terms" do
    it "is accessible without signing in" do
      get help_terms_path
      expect(response).to have_http_status(:ok)
    end
  end
end
