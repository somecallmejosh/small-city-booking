require "rails_helper"

RSpec.describe BookingMailer, type: :mailer do
  let(:user) { create(:user, name: "Jordan") }
  let(:slot) { create(:slot, starts_at: 1.day.from_now.beginning_of_hour, status: "reserved") }
  let(:booking) do
    b = create(:booking, user: user, total_cents: 7500, stripe_receipt_url: "https://receipt.stripe.com/test")
    create(:booking_slot, booking: b, slot: slot)
    b
  end

  describe "#confirmation" do
    let(:mail) { described_class.confirmation(booking) }

    it "sends to the user's email address" do
      expect(mail.to).to eq([ user.email_address ])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Your session is confirmed — Small City Studio")
    end

    it "includes the session time range in the HTML body" do
      expect(mail.html_part.body.to_s).to include("from")
    end

    it "includes the session time range in the text body" do
      expect(mail.text_part.body.to_s).to include("from")
    end

    it "includes the total paid formatted as dollars" do
      expect(mail.html_part.body.to_s).to include("75.00")
    end

    it "includes the receipt link when present" do
      expect(mail.html_part.body.to_s).to include("receipt.stripe.com")
    end

    it "omits the receipt section when stripe_receipt_url is nil" do
      booking.update!(stripe_receipt_url: nil)
      mail_no_receipt = described_class.confirmation(booking)
      expect(mail_no_receipt.html_part.body.to_s).not_to include("receipt")
    end

    it "addresses the user by name" do
      expect(mail.html_part.body.to_s).to include("Jordan")
    end

    it "falls back to 'there' when name is blank" do
      user.update!(name: nil)
      mail_no_name = described_class.confirmation(booking)
      expect(mail_no_name.html_part.body.to_s).to include("Hi there")
    end
  end

  describe "#reminder" do
    let(:mail) { described_class.reminder(booking) }

    it "sends to the user's email address" do
      expect(mail.to).to eq([ user.email_address ])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Your session is tomorrow — Small City Studio")
    end

    it "includes 'tomorrow' in the HTML body" do
      expect(mail.html_part.body.to_s).to include("tomorrow")
    end

    it "includes 'tomorrow' in the text body" do
      expect(mail.text_part.body.to_s).to include("tomorrow")
    end

    it "includes the session time in the HTML body" do
      expect(mail.html_part.body.to_s).to include("from")
    end

    it "addresses the user by name" do
      expect(mail.html_part.body.to_s).to include("Jordan")
    end

    it "falls back to 'there' when name is blank" do
      user.update!(name: nil)
      mail_no_name = described_class.reminder(booking)
      expect(mail_no_name.html_part.body.to_s).to include("Hi there")
    end
  end

  describe "#follow_up" do
    let(:mail) { described_class.follow_up(booking) }

    it "sends to the user's email address" do
      expect(mail.to).to eq([ user.email_address ])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("How was your session? — Small City Studio")
    end

    it "includes a link to book again in the HTML body" do
      expect(mail.html_part.body.to_s).to include(root_url)
    end

    it "includes a link to book again in the text body" do
      expect(mail.text_part.body.to_s).to include(root_url)
    end

    it "addresses the user by name" do
      expect(mail.html_part.body.to_s).to include("Jordan")
    end

    it "falls back to 'there' when name is blank" do
      user.update!(name: nil)
      mail_no_name = described_class.follow_up(booking)
      expect(mail_no_name.html_part.body.to_s).to include("Hi there")
    end
  end
end
