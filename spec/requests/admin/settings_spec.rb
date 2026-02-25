require "rails_helper"

RSpec.describe "Admin::Settings", type: :request do
  let(:admin) { create(:user, :admin) }

  before do
    post session_path, params: { email_address: admin.email_address, password: "securepassword1" }
  end

  describe "GET /admin/settings" do
    it "returns 200" do
      get admin_settings_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/settings/edit" do
    it "returns 200" do
      get edit_admin_settings_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/settings" do
    context "with valid params" do
      it "updates the hourly rate and redirects to show" do
        patch admin_settings_path, params: {
          studio_setting: {
            hourly_rate:         "75.00",
            cancellation_hours:  "48",
            studio_name:         "Updated Studio",
            studio_description:  "Great vibes."
          }
        }

        expect(response).to redirect_to(admin_settings_path)
        settings = StudioSetting.current
        expect(settings.hourly_rate_cents).to eq(7500)
        expect(settings.cancellation_hours).to eq(48)
        expect(settings.studio_name).to eq("Updated Studio")
      end
    end

    context "with invalid params (hourly rate = 0)" do
      it "re-renders edit with unprocessable status" do
        patch admin_settings_path, params: {
          studio_setting: { hourly_rate: "0", cancellation_hours: "24" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
