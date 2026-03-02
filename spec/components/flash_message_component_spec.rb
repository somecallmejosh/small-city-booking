require "rails_helper"

RSpec.describe FlashMessageComponent, type: :component do
  it "renders a notice banner with status role" do
    render_inline(described_class.new(type: :notice, message: "Saved successfully"))

    expect(page).to have_css("[role='status']")
    expect(page).to have_text("Saved successfully")
  end

  it "renders an alert banner with alert role" do
    render_inline(described_class.new(type: :alert, message: "Something looks off"))

    expect(page).to have_css("[role='alert']")
    expect(page).to have_text("Something looks off")
  end

  it "renders an error banner with alert role" do
    render_inline(described_class.new(type: :error, message: "An error occurred"))

    expect(page).to have_css("[role='alert']")
    expect(page).to have_text("An error occurred")
  end

  it "includes a dismiss button with an accessible label" do
    render_inline(described_class.new(type: :notice, message: "Done"))

    expect(page).to have_css("button[aria-label='Dismiss']")
  end

  it "applies green container classes for notice type" do
    render_inline(described_class.new(type: :notice, message: "Good"))

    expect(page).to have_css(".bg-red-50")
  end

  it "applies red container classes for error type" do
    render_inline(described_class.new(type: :error, message: "Bad"))

    expect(page).to have_css(".bg-red-50")
  end
end
