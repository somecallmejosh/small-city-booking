require "rails_helper"

RSpec.describe "Admin::PromoCodes", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:customer) { create(:user) }

  def sign_in(u = admin)
    post session_path, params: { email_address: u.email_address, password: "securepassword1" }
  end

  describe "GET /admin/promo_codes" do
    before { sign_in }

    it "returns 200" do
      get admin_promo_codes_path
      expect(response).to have_http_status(:ok)
    end

    it "lists promo codes" do
      promo = create(:promo_code, name: "Summer Sale")
      get admin_promo_codes_path
      expect(response.body).to include("Summer Sale")
    end

    context "when not an admin" do
      before { sign_in(customer) }

      it "redirects to root" do
        get admin_promo_codes_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/promo_codes/new" do
    before { sign_in }

    it "returns 200" do
      get new_admin_promo_code_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/promo_codes" do
    before { sign_in }

    let(:valid_params) do
      {
        promo_code: {
          name:             "Holiday Discount",
          code:             "HOLIDAY20",
          discount_percent: 20,
          start_date:       Date.current.to_s,
          end_date:         (Date.current + 30.days).to_s,
          active:           "1"
        }
      }
    end

    it "creates a promo code and redirects to show" do
      expect { post admin_promo_codes_path, params: valid_params }
        .to change(PromoCode, :count).by(1)

      promo = PromoCode.last
      expect(promo.code).to eq("holiday20")
      expect(response).to redirect_to(admin_promo_code_path(promo))
    end

    it "re-renders new with errors for invalid params" do
      post admin_promo_codes_path, params: { promo_code: { name: "", code: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/promo_codes/:id" do
    before { sign_in }

    it "returns 200 and shows code details" do
      promo = create(:promo_code, name: "Black Friday")
      get admin_promo_code_path(promo)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Black Friday")
    end
  end

  describe "GET /admin/promo_codes/:id/edit" do
    before { sign_in }

    it "returns 200" do
      promo = create(:promo_code)
      get edit_admin_promo_code_path(promo)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/promo_codes/:id" do
    before { sign_in }

    it "updates the promo code and redirects to show" do
      promo = create(:promo_code, name: "Old Name")
      patch admin_promo_code_path(promo), params: { promo_code: { name: "New Name" } }

      expect(promo.reload.name).to eq("New Name")
      expect(response).to redirect_to(admin_promo_code_path(promo))
    end

    it "re-renders edit with errors for invalid params" do
      promo = create(:promo_code)
      patch admin_promo_code_path(promo),
            params: { promo_code: { discount_percent: 0 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/promo_codes/:id" do
    before { sign_in }

    it "destroys a code with no usages and redirects with notice" do
      promo = create(:promo_code)

      expect { delete admin_promo_code_path(promo) }
        .to change(PromoCode, :count).by(-1)

      expect(response).to redirect_to(admin_promo_codes_path)
      follow_redirect!
      expect(response.body).to match(/deleted/i)
    end

    it "prevents destruction when usages exist and redirects with alert" do
      promo   = create(:promo_code)
      booking = create(:booking)
      create(:promo_code_usage, promo_code: promo, user: booking.user, booking: booking)

      expect { delete admin_promo_code_path(promo) }
        .not_to change(PromoCode, :count)

      expect(response).to redirect_to(admin_promo_code_path(promo))
      follow_redirect!
      expect(response.body).to match(/cannot delete|restrict/i)
    end

    context "when not an admin" do
      before { sign_in(customer) }

      it "redirects to root" do
        promo = create(:promo_code)
        delete admin_promo_code_path(promo)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
