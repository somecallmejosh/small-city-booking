require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        get root_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      it "returns 200" do
        user = create(:user)
        post session_path, params: { email_address: user.email_address, password: "securepassword1" }
        get root_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
