require "rails_helper"

RSpec.describe WaitlistMailer, type: :mailer do
  describe "#slots_available" do
    let(:user)  { create(:user, name: "Jordan") }
    let(:entry) { create(:waitlist_entry, user: user) }
    let(:mail)  { described_class.slots_available(entry) }

    it "sends to the user's email address" do
      expect(mail.to).to eq([ user.email_address ])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Studio slots are available — Small City Studio")
    end

    it "includes a link to the home page in the HTML body" do
      expect(mail.html_part.body.to_s).to include(root_url)
    end

    it "includes a link to the home page in the text body" do
      expect(mail.text_part.body.to_s).to include(root_url)
    end

    it "addresses the user by name" do
      expect(mail.html_part.body.to_s).to include("Jordan")
    end

    it "falls back to 'there' when name is blank" do
      user.update!(name: nil)
      mail_no_name = described_class.slots_available(entry)
      expect(mail_no_name.html_part.body.to_s).to include("Hi there")
    end
  end
end
