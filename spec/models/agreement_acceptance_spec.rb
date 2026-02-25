require "rails_helper"

RSpec.describe AgreementAcceptance, type: :model do
  it "is valid with valid attributes" do
    acceptance = build(:agreement_acceptance)
    expect(acceptance).to be_valid
  end

  it "requires accepted_at" do
    acceptance = build(:agreement_acceptance, accepted_at: nil)
    expect(acceptance).not_to be_valid
  end
end
