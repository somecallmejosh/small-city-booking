require "rails_helper"

RSpec.describe StyleHelper, type: :helper do
  describe "#btn_primary" do
    it "returns a non-empty string of CSS classes" do
      expect(helper.btn_primary).to include("bg-stone-900")
    end
  end

  describe "#btn_secondary" do
    it "returns a non-empty string of CSS classes" do
      expect(helper.btn_secondary).to include("border-stone-300")
    end
  end

  describe "#btn_danger" do
    it "returns a non-empty string of CSS classes" do
      expect(helper.btn_danger).to include("bg-red-600")
    end
  end

  describe "#input_field" do
    it "returns a non-empty string of CSS classes" do
      expect(helper.input_field).to include("rounded-lg")
    end
  end

  describe "#card" do
    it "returns a non-empty string of CSS classes" do
      expect(helper.card).to include("rounded-xl")
    end
  end

  describe "#page_container" do
    it "returns a non-empty string of CSS classes" do
      expect(helper.page_container).to include("max-w-2xl")
    end
  end
end
