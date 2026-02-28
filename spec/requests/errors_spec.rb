require "rails_helper"

RSpec.describe "Errors", type: :request do
  describe "GET /404" do
    it "returns 404 status" do
      get "/404"
      expect(response).to have_http_status(:not_found)
    end

    it "shows the not found message" do
      get "/404"
      expect(response.body).to include("Page not found")
    end

    it "shows the app nav" do
      get "/404"
      expect(response.body).to include("Small City Studio")
    end

    it "includes a link back to home" do
      get "/404"
      expect(response.body).to include(root_path)
    end
  end

  describe "GET /422" do
    it "returns 422 status" do
      get "/422"
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "shows the unprocessable message" do
      get "/422"
      expect(response.body).to include("Request could not be processed")
    end

    it "includes a link back to home" do
      get "/422"
      expect(response.body).to include(root_path)
    end
  end

  describe "GET /500" do
    it "returns 500 status" do
      get "/500"
      expect(response).to have_http_status(:internal_server_error)
    end

    it "shows the server error message" do
      get "/500"
      expect(response.body).to include("Something went wrong")
    end

    it "includes a link back to home" do
      get "/500"
      expect(response.body).to include(root_path)
    end
  end
end
