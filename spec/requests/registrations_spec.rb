require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "GET /registration/new" do
    it "returns 200" do
      get new_registration_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /registration" do
    let(:valid_params) do
      {
        user: {
          email_address:          "newartist@example.com",
          password:               "securepassword1",
          password_confirmation:  "securepassword1",
          name:                   "DJ Test"
        }
      }
    end

    it "creates a user and redirects to sign-in with notice" do
      expect {
        post registration_path, params: valid_params
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(new_session_path)
      follow_redirect!
      expect(response.body).to include("Check your email")
    end

    it "creates the user as unverified" do
      post registration_path, params: valid_params
      expect(User.find_by(email_address: "newartist@example.com").email_verified?).to be false
    end

    it "does not sign the user in automatically" do
      post registration_path, params: valid_params
      follow_redirect!
      # Should be on sign-in page, not home page
      expect(response.body).not_to include("Sign Out")
    end

    it "enqueues a verification email" do
      expect {
        post registration_path, params: valid_params
      }.to have_enqueued_mail(RegistrationsMailer, :verify_email)
    end

    it "does not allow admin to be set via params" do
      post registration_path, params: valid_params.deep_merge(user: { admin: true })
      expect(User.find_by(email_address: "newartist@example.com")&.admin).to be false
    end

    context "with invalid params" do
      it "returns unprocessable entity for missing email" do
        post registration_path, params: { user: { email_address: "", password: "securepassword1",
                                                   password_confirmation: "securepassword1" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns unprocessable entity for short password" do
        post registration_path, params: { user: { email_address: "x@example.com",
                                                   password: "short",
                                                   password_confirmation: "short" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns unprocessable entity for mismatched passwords" do
        post registration_path, params: { user: { email_address: "x@example.com",
                                                   password: "securepassword1",
                                                   password_confirmation: "differentpassword1" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns unprocessable entity for duplicate email" do
        create(:user, email_address: "newartist@example.com")
        post registration_path, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
