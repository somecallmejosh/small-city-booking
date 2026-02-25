require "rails_helper"

RSpec.describe ConfirmationDialogComponent, type: :component do
  it "renders the title and message" do
    render_inline(described_class.new(
      title: "Cancel booking?",
      message: "This action cannot be undone.",
      confirm_url: "/bookings/1/cancel"
    ))

    expect(page).to have_text("Cancel booking?")
    expect(page).to have_text("This action cannot be undone.")
  end

  it "uses default label values" do
    render_inline(described_class.new(
      title: "Are you sure?",
      message: "Confirm to continue.",
      confirm_url: "/bookings/1/cancel"
    ))

    expect(page).to have_button("Confirm")
    expect(page).to have_button("Cancel")
  end

  it "renders custom confirm and cancel labels" do
    render_inline(described_class.new(
      title: "Delete?",
      message: "This is permanent.",
      confirm_url: "/items/1",
      confirm_label: "Yes, delete",
      cancel_label: "Go back"
    ))

    expect(page).to have_button("Yes, delete")
    expect(page).to have_button("Go back")
  end

  it "has aria-modal and aria-labelledby attributes" do
    render_inline(described_class.new(
      title: "Confirm action",
      message: "Are you sure?",
      confirm_url: "/action"
    ))

    expect(page).to have_css("dialog[aria-modal='true']")
    expect(page).to have_css("dialog[aria-labelledby]")
  end
end
