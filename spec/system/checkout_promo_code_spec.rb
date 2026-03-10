require "rails_helper"

RSpec.describe "Checkout promo code", type: :system, js: true do
  let(:user)      { create(:user, :verified) }
  let!(:agreement) { create(:agreement) }
  let!(:promo)    { create(:promo_code, code: "save20", discount_percent: 20) }

  before do
    driven_by(:cuprite)
    create(:slot, status: "open", starts_at: 2.days.from_now.beginning_of_hour)

    # Sign in
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password",      with: "securepassword1"
    click_button "Sign in"

    # Select slot and proceed to checkout
    find("[data-slot-selection-target='slot']").click
    find("[data-slot-selection-target='checkoutButton']").click
    expect(page).to have_current_path(new_booking_path, wait: 10)
  end

  it "applies a valid promo code and updates the total inline" do
    original_total = find("#total_section").text

    fill_in "promo_code", with: "SAVE20"
    click_button "Apply"

    # Turbo Stream swaps total_section — wait for discount line
    expect(page).to have_text("Discount (20% off)", wait: 5)
    expect(find("#total_section").text).not_to eq(original_total)

    # Countdown timer is still running
    expect(page).to have_css("[data-countdown-timer-target='display']")
  end

  it "shows an error for an invalid code" do
    fill_in "promo_code", with: "BADCODE"
    click_button "Apply"

    expect(page).to have_text(/invalid.*expired/i, wait: 5)
    expect(page).not_to have_text("Discount")
  end

  it "clears the promo when a blank code is submitted" do
    # First apply a valid code
    fill_in "promo_code", with: "SAVE20"
    click_button "Apply"
    expect(page).to have_text("Discount (20% off)", wait: 5)

    # Then clear it
    fill_in "promo_code", with: ""
    click_button "Apply"
    expect(page).not_to have_text("Discount", wait: 5)
  end
end
