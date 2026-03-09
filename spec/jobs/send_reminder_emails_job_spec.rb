require "rails_helper"

RSpec.describe SendReminderEmailsJob, type: :job do
  def booking_with_slot(status:, starts_at:, reminder_sent_at: nil)
    booking = create(:booking, status: status, reminder_sent_at: reminder_sent_at)
    slot = create(:slot, starts_at: starts_at, status: "reserved")
    create(:booking_slot, booking: booking, slot: slot)
    booking
  end

  describe "#perform" do
    it "enqueues a reminder for a confirmed booking with earliest slot ~24 hours away" do
      booking_with_slot(status: "confirmed", starts_at: 24.hours.from_now)

      expect { described_class.new.perform }
        .to have_enqueued_mail(BookingMailer, :reminder)
    end

    it "stamps reminder_sent_at after sending" do
      booking = booking_with_slot(status: "confirmed", starts_at: 24.hours.from_now)

      described_class.new.perform

      expect(booking.reload.reminder_sent_at).to be_present
    end

    it "does not send when the earliest slot is outside the 23–25 hour window" do
      booking_with_slot(status: "confirmed", starts_at: 48.hours.from_now)

      expect { described_class.new.perform }
        .not_to have_enqueued_mail(BookingMailer, :reminder)
    end

    it "does not send when reminder_sent_at is already set" do
      booking_with_slot(
        status: "confirmed",
        starts_at: 24.hours.from_now,
        reminder_sent_at: 1.hour.ago
      )

      expect { described_class.new.perform }
        .not_to have_enqueued_mail(BookingMailer, :reminder)
    end

    it "does not send for pending bookings in the window" do
      booking_with_slot(status: "pending", starts_at: 24.hours.from_now)

      expect { described_class.new.perform }
        .not_to have_enqueued_mail(BookingMailer, :reminder)
    end

    it "does not send for cancelled bookings in the window" do
      booking_with_slot(status: "cancelled", starts_at: 24.hours.from_now)

      expect { described_class.new.perform }
        .not_to have_enqueued_mail(BookingMailer, :reminder)
    end

    it "enqueues one mail per qualifying booking" do
      booking_with_slot(status: "confirmed", starts_at: 24.hours.from_now)
      booking_with_slot(status: "confirmed", starts_at: 24.hours.from_now + 30.minutes)

      expect { described_class.new.perform }
        .to have_enqueued_mail(BookingMailer, :reminder).twice
    end
  end
end
