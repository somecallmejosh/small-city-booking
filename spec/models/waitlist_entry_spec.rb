require "rails_helper"

RSpec.describe WaitlistEntry, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      entry = build(:waitlist_entry)
      expect(entry).to be_valid
    end

    it "rejects an invalid status" do
      entry = build(:waitlist_entry, status: "bogus")
      expect(entry).not_to be_valid
    end

    it "accepts all valid statuses" do
      WaitlistEntry::STATUSES.each do |status|
        entry = build(:waitlist_entry, status: status)
        expect(entry).to be_valid, "expected #{status} to be valid"
      end
    end

    it "requires a user" do
      entry = build(:waitlist_entry, user: nil)
      expect(entry).not_to be_valid
    end

    it "enforces one entry per user at the database level" do
      user = create(:user)
      create(:waitlist_entry, user: user)
      duplicate = build(:waitlist_entry, user: user)
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "scopes" do
    it ".pending returns only pending entries" do
      pending_entry  = create(:waitlist_entry)
      notified_entry = create(:waitlist_entry, :notified, user: create(:user))

      expect(WaitlistEntry.pending).to include(pending_entry)
      expect(WaitlistEntry.pending).not_to include(notified_entry)
    end

    it ".notified returns only notified entries" do
      pending_entry  = create(:waitlist_entry)
      notified_entry = create(:waitlist_entry, :notified, user: create(:user))

      expect(WaitlistEntry.notified).to include(notified_entry)
      expect(WaitlistEntry.notified).not_to include(pending_entry)
    end

    it ".ordered returns entries in ascending created_at order" do
      first  = create(:waitlist_entry, created_at: 2.days.ago)
      second = create(:waitlist_entry, created_at: 1.day.ago, user: create(:user))

      expect(WaitlistEntry.ordered.to_a).to eq([ first, second ])
    end
  end

  describe "#notify!" do
    it "transitions status to notified" do
      entry = create(:waitlist_entry)
      entry.notify!
      expect(entry.reload.status).to eq("notified")
    end

    it "sets notified_at" do
      entry = create(:waitlist_entry)
      entry.notify!
      expect(entry.reload.notified_at).to be_present
    end
  end
end
