require "rails_helper"

RSpec.describe "Admin authorization", type: :request do
  let(:user)  { create(:user) }
  let(:admin) { create(:user, :admin) }

  shared_examples "requires admin" do |method, path_proc|
    context "when unauthenticated" do
      it "redirects to sign-in" do
        public_send(method, instance_exec(&path_proc))
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when signed in as a non-admin" do
      before do
        post session_path, params: { email_address: user.email_address, password: "securepassword1" }
      end

      it "redirects to root with an alert" do
        public_send(method, instance_exec(&path_proc))
        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as admin" do
      before do
        post session_path, params: { email_address: admin.email_address, password: "securepassword1" }
      end

      it "returns 200" do
        public_send(method, instance_exec(&path_proc))
        expect(response).to have_http_status(:ok)
      end
    end
  end

  include_examples "requires admin", :get, -> { admin_root_path }
  include_examples "requires admin", :get, -> { admin_slots_path }
  include_examples "requires admin", :get, -> { admin_agreement_path }
  include_examples "requires admin", :get, -> { admin_settings_path }
end
