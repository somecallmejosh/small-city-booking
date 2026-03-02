require "rails_helper"

RSpec.describe RegistrationsMailer, type: :mailer do
  describe "#verify_email" do
    let(:user) { create(:user, name: "Chase") }
    let(:mail) { described_class.verify_email(user) }

    it "sends to the user's email address" do
      expect(mail.to).to eq([ user.email_address ])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Verify your email — Small City Studio")
    end

    it "includes a verification link in the HTML body" do
      expect(mail.html_part.body.to_s).to include("email_verifications/")
    end

    it "includes a verification link in the text body" do
      expect(mail.text_part.body.to_s).to include("email_verifications/")
    end

    it "addresses the user by name" do
      expect(mail.html_part.body.to_s).to include("Chase")
    end

    it "falls back to 'there' when name is blank" do
      user.update!(name: nil)
      mail_no_name = described_class.verify_email(user)
      expect(mail_no_name.html_part.body.to_s).to include("Hi there")
    end
  end
end
