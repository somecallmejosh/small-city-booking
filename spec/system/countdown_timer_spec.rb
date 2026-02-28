require "rails_helper"

RSpec.describe "Countdown timer", type: :system do
  let(:user)      { create(:user) }
  let!(:agreement) { create(:agreement) }

  before { driven_by(:cuprite) }

  it "renders the countdown timer on the checkout page and pay button is disabled without agreement checkbox" do
    # Create a fresh open slot
    create(:slot, status: "open", starts_at: 2.days.from_now.beginning_of_hour)

    # Sign in via the form
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "securepassword1"
    click_button "Sign in"

    expect(page).to have_current_path(root_path)

    # Click the slot to select it
    slot_button = find("[data-slot-selection-target='slot']")
    slot_button.click

    # Click "Continue to Checkout" (Stimulus submits the form with selected slot IDs)
    find("[data-slot-selection-target='checkoutButton']").click

    # Should redirect to checkout page
    expect(page).to have_current_path(new_booking_path, wait: 10)

    # Countdown timer element is present (element has multiple controllers; use word-match selector)
    expect(page).to have_css("[data-controller~='countdown-timer']")
    expect(page).to have_css("[data-countdown-timer-target='display']")

    # Pay button is initially disabled (agreement checkbox not checked)
    pay_button = find("button#pay_button")
    expect(pay_button).to be_disabled
  end
end
