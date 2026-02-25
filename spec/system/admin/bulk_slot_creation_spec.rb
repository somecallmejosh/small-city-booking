require "rails_helper"

RSpec.describe "Admin bulk slot creation", type: :system do
  let(:admin) { create(:user, :admin) }
  let(:monday) { Date.today.next_occurring(:monday) }
  let(:sunday) { monday + 6 }

  before do
    driven_by(:rack_test)
    visit new_session_path
    fill_in "email_address", with: admin.email_address
    fill_in "password", with: "securepassword1"
    click_button "Sign in"
  end

  it "creates slots for selected days and time range" do
    visit bulk_new_admin_slots_path

    # Select Monday and Wednesday
    check "Mon"
    check "Wed"

    fill_in "start_date", with: monday.to_s
    fill_in "end_date",   with: sunday.to_s

    select "3:00 PM", from: "start_hour"
    select "6:00 PM", from: "end_hour"

    expect {
      click_button "Create Slots"
    }.to change(Slot, :count).by(6) # 3 hours × 2 days

    expect(page).to have_current_path(admin_slots_path)
    expect(page).to have_content("Created 6 slot(s)")
  end
end
