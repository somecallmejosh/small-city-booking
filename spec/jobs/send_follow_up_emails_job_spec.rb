require "rails_helper"

RSpec.describe SendFollowUpEmailsJob, type: :job do
  def booking_with_slot(status:, starts_at:, follow_up_sent_at: nil)
    booking = create(:booking, status: status, follow_up_sent_at: follow_up_sent_at)
    slot = create(:slot, starts_at: starts_at, status: "reserved")
    create(:booking_slot, booking: booking, slot: slot)
    booking
  end

  describe "#perform" do
    it "enqueues a follow-up for a completed booking whose last slot started 4+ hours ago" do
      booking_with_slot(status: "completed", starts_at: 5.hours.ago)

      expect { described_class.new.perform }
        .to have_enqueued_mail(BookingMailer, :follow_up)
    end

    it "stamps follow_up_sent_at after sending" do
      booking = booking_with_slot(status: "completed", starts_at: 5.hours.ago)

      described_class.new.perform

      expect(booking.reload.follow_up_sent_at).to be_present
    end

    it "does not send when the last slot started fewer than 4 hours ago" do
      booking_with_slot(status: "completed", starts_at: 2.hours.ago)

      expect { described_class.new.perform }
        .not_to have_enqueued_mail(BookingMailer, :follow_up)
    end

    it "does not send when follow_up_sent_at is already set" do
      booking_with_slot(
        status: "completed",
        starts_at: 5.hours.ago,
        follow_up_sent_at: 1.hour.ago
      )

      expect { described_class.new.perform }
        .not_to have_enqueued_mail(BookingMailer, :follow_up)
    end

    it "does not send for confirmed bookings with past slots" do
      booking_with_slot(status: "confirmed", starts_at: 5.hours.ago)

      expect { described_class.new.perform }
        .not_to have_enqueued_mail(BookingMailer, :follow_up)
    end

    it "does not send for cancelled bookings" do
      booking_with_slot(status: "cancelled", starts_at: 5.hours.ago)

      expect { described_class.new.perform }
        .not_to have_enqueued_mail(BookingMailer, :follow_up)
    end

    it "uses MAX(slots.starts_at) so multi-slot bookings are not sent prematurely" do
      booking = create(:booking, status: "completed")
      create(:booking_slot, booking: booking, slot: create(:slot, starts_at: 8.hours.ago, status: "reserved"))
      create(:booking_slot, booking: booking, slot: create(:slot, starts_at: 2.hours.ago, status: "reserved"))

      expect { described_class.new.perform }
        .not_to have_enqueued_mail(BookingMailer, :follow_up)
    end

    it "enqueues one mail per qualifying booking" do
      booking_with_slot(status: "completed", starts_at: 5.hours.ago)
      booking_with_slot(status: "completed", starts_at: 6.hours.ago)

      expect { described_class.new.perform }
        .to have_enqueued_mail(BookingMailer, :follow_up).twice
    end
  end
end
