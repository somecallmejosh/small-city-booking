require "rails_helper"

RSpec.describe "EmailVerifications", type: :request do
  let(:user) { create(:user) }

  describe "GET /email_verifications/new" do
    it "returns 200" do
      get new_email_verification_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /email_verifications (resend)" do
    it "always redirects to sign-in with a non-revealing notice" do
      post email_verifications_path, params: { email_address: user.email_address }
      expect(response).to redirect_to(new_session_path)
    end

    it "enqueues verification email for an unverified user" do
      expect {
        post email_verifications_path, params: { email_address: user.email_address }
      }.to have_enqueued_mail(RegistrationsMailer, :verify_email)
    end

    it "does not enqueue email for a verified user" do
      user.verify!
      expect {
        post email_verifications_path, params: { email_address: user.email_address }
      }.not_to have_enqueued_mail(RegistrationsMailer, :verify_email)
    end

    it "does not enqueue email for an unknown address" do
      expect {
        post email_verifications_path, params: { email_address: "nobody@example.com" }
      }.not_to have_enqueued_mail(RegistrationsMailer, :verify_email)
    end
  end

  describe "GET /email_verifications/:token (verify link)" do
    context "with a valid token" do
      let(:token) { user.generate_token_for(:email_verification) }

      it "marks the user as verified" do
        get email_verification_path(token)
        expect(user.reload.email_verified?).to be true
      end

      it "signs the user in and redirects to root" do
        get email_verification_path(token)
        expect(response).to redirect_to(root_path)
      end
    end

    context "with an already-verified user (token invalidated by verify!)" do
      it "redirects to the resend page (token is invalid after verify! changes email_verified_at)" do
        token = user.generate_token_for(:email_verification)
        user.verify!
        get email_verification_path(token)
        expect(response).to redirect_to(new_email_verification_path)
      end
    end

    context "with an invalid token" do
      it "redirects to resend page with alert" do
        get email_verification_path("not_a_real_token")
        expect(response).to redirect_to(new_email_verification_path)
        follow_redirect!
        expect(response.body).to match(/invalid or has expired/i)
      end
    end
  end
end
