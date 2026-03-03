require "rails_helper"

RSpec.describe NotifyWaitlistJob, type: :job do
  def available_slot
    create(:slot, status: "open", starts_at: 1.day.from_now.beginning_of_hour)
  end

  describe "#perform" do
    it "does nothing when no pending waitlist entries exist" do
      available_slot
      create(:waitlist_entry, :notified, user: create(:user))

      expect { described_class.new.perform }
        .not_to have_enqueued_mail(WaitlistMailer, :slots_available)
    end

    it "does nothing when no available slots exist in the window" do
      create(:waitlist_entry)

      expect { described_class.new.perform }
        .not_to have_enqueued_mail(WaitlistMailer, :slots_available)
    end

    it "enqueues a mail for each pending entry when slots are available" do
      available_slot
      entry1 = create(:waitlist_entry, user: create(:user))
      entry2 = create(:waitlist_entry, user: create(:user))

      expect { described_class.new.perform }
        .to have_enqueued_mail(WaitlistMailer, :slots_available).twice
    end

    it "marks each pending entry as notified" do
      available_slot
      entry = create(:waitlist_entry)

      described_class.new.perform

      expect(entry.reload.status).to eq("notified")
      expect(entry.reload.notified_at).to be_present
    end

    it "does not notify already-notified entries" do
      available_slot
      create(:waitlist_entry, :notified, user: create(:user))

      expect { described_class.new.perform }
        .not_to have_enqueued_mail(WaitlistMailer, :slots_available)
    end
  end
end
