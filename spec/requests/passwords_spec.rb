require "rails_helper"

RSpec.describe "Passwords", type: :request do
  describe "GET /passwords/new" do
    it "returns 200" do
      get new_password_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /passwords" do
    context "when a user exists with that email" do
      it "redirects to sign-in with a notice (does not reveal whether user exists)" do
        create(:user, email_address: "alice@example.com")
        post passwords_path, params: { email_address: "alice@example.com" }
        expect(response).to redirect_to(new_session_path)
        follow_redirect!
        expect(response.body).to include("Password reset instructions sent")
      end
    end

    context "when no user exists with that email" do
      it "redirects to sign-in with the same notice (no information leakage)" do
        post passwords_path, params: { email_address: "nobody@example.com" }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /passwords/:token/edit" do
    it "redirects to new_password_path with an alert for an invalid token" do
      get edit_password_path(token: "invalid_token")
      expect(response).to redirect_to(new_password_path)
    end
  end

  describe "PATCH /passwords/:token" do
    let(:user) { create(:user) }

    it "resets the password with a valid token" do
      token = user.generate_token_for(:password_reset)
      patch password_path(token: token), params: { password: "newpassword123", password_confirmation: "newpassword123" }
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects back with alert when passwords do not match" do
      token = user.generate_token_for(:password_reset)
      patch password_path(token: token), params: { password: "newpassword123", password_confirmation: "differentpassword" }
      expect(response).to redirect_to(edit_password_path(token))
    end
  end
end
