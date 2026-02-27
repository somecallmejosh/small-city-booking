require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, email_address: "test@example.com", password: "securepassword1") }

  describe "GET /session/new" do
    it "returns 200" do
      get new_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /session" do
    context "with valid credentials" do
      it "signs the user in and redirects" do
        user # ensure user is created
        post session_path, params: { email_address: "test@example.com", password: "securepassword1" }
        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid credentials" do
      it "redirects back to sign-in with an alert" do
        user
        post session_path, params: { email_address: "test@example.com", password: "wrongpassword" }
        expect(response).to redirect_to(new_session_path)
        follow_redirect!
        expect(response.body).to include("Try another email address or password")
      end
    end
  end

  describe "DELETE /session" do
    it "signs the user out and redirects to sign-in" do
      user
      post session_path, params: { email_address: user.email_address, password: "securepassword1" }
      delete session_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "authentication redirect" do
    it "stores the originally requested URL and redirects back after sign-in" do
      user # ensure user exists
      get bookings_path  # requires authentication → stored as return_to and redirected to sign-in
      expect(response).to redirect_to(new_session_path)

      post session_path, params: { email_address: "test@example.com", password: "securepassword1" }
      expect(response).to redirect_to(bookings_url)
    end
  end
end
