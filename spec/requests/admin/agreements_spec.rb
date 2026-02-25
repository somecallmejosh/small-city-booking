require "rails_helper"

RSpec.describe "Admin::Agreements", type: :request do
  let(:admin) { create(:user, :admin) }

  before do
    post session_path, params: { email_address: admin.email_address, password: "securepassword1" }
  end

  describe "GET /admin/agreement" do
    it "returns 200 with no agreements" do
      get admin_agreement_path
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 and shows the current agreement" do
      agreement = create(:agreement)
      get admin_agreement_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Version #{agreement.version}")
    end
  end

  describe "GET /admin/agreement/edit" do
    it "returns 200" do
      get edit_admin_agreement_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/agreement" do
    it "creates a new agreement with published_at set and redirects to show" do
      expect {
        patch admin_agreement_path, params: { agreement: { body: "New terms content." } }
      }.to change(Agreement, :count).by(1)

      expect(response).to redirect_to(admin_agreement_path)
      expect(Agreement.last.published_at).not_to be_nil
    end

    it "increments the version number on successive saves" do
      patch admin_agreement_path, params: { agreement: { body: "Version one." } }
      patch admin_agreement_path, params: { agreement: { body: "Version two." } }

      expect(Agreement.count).to eq(2)
      expect(Agreement.order(:version).pluck(:version)).to eq([ 1, 2 ])
    end
  end
end
