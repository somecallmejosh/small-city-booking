require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  describe "#reset" do
    let(:user) { create(:user, email_address: "test@example.com") }
    let(:mail) { described_class.reset(user) }

    it "sends to the user's email address" do
      expect(mail.to).to eq([ "test@example.com" ])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Reset your password")
    end

    it "renders the HTML body" do
      expect(mail.html_part.body.to_s).to be_present
    end

    it "renders the text body" do
      expect(mail.text_part.body.to_s).to be_present
    end
  end
end
