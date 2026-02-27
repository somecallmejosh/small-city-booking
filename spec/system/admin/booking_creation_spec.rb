require "rails_helper"

RSpec.describe "Admin booking creation", type: :system do
  let(:admin)    { create(:user, :admin) }
  let(:customer) { create(:user, name: "Jane Doe", email_address: "jane@example.com") }
  let(:agreement) { create(:agreement) }
  let(:open_slot) { create(:slot, starts_at: 2.days.from_now.beginning_of_hour + 14.hours) }

  before do
    driven_by(:rack_test)
    agreement
    StudioSetting.current.update!(hourly_rate_cents: 6000)
    customer
    open_slot

    visit new_session_path
    fill_in "email_address", with: admin.email_address
    fill_in "password",      with: "securepassword1"
    click_button "Sign in"
  end

  it "creates a booking without a payment link" do
    visit new_admin_booking_path

    select "Jane Doe (jane@example.com)", from: "booking_user_id"
    check open_slot.starts_at.strftime("%a, %b %-d %Y · %-I:%M %p")

    expect {
      click_button "Create Booking"
    }.to change(Booking, :count).by(1)

    expect(page).to have_current_path(admin_booking_path(Booking.last))
    expect(page).to have_content("Booking created")

    booking = Booking.last
    expect(booking.admin_created).to be true
    expect(booking.total_cents).to eq(6000)
    expect(open_slot.reload.status).to eq("reserved")
  end

  it "creates a booking with a Stripe Payment Link" do
    stub_request(:post, "https://api.stripe.com/v1/prices")
      .to_return(
        status:  200,
        headers: { "Content-Type" => "application/json" },
        body:    JSON.generate({ id: "price_test_fake", object: "price" })
      )
    stub_request(:post, "https://api.stripe.com/v1/payment_links")
      .to_return(
        status:  200,
        headers: { "Content-Type" => "application/json" },
        body:    JSON.generate({
          id:     "plink_test_fake",
          object: "payment_link",
          url:    "https://buy.stripe.com/test_link"
        })
      )

    visit new_admin_booking_path

    select "Jane Doe (jane@example.com)", from: "booking_user_id"
    check open_slot.starts_at.strftime("%a, %b %-d %Y · %-I:%M %p")
    check "Generate Stripe Payment Link"

    click_button "Create Booking"

    expect(page).to have_current_path(admin_booking_path(Booking.last))
    expect(page).to have_content("https://buy.stripe.com/test_link")
  end
end
