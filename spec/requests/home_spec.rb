require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "when unauthenticated" do
      it "returns 200 (home is publicly accessible)" do
        get root_path
        expect(response).to have_http_status(:ok)
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
