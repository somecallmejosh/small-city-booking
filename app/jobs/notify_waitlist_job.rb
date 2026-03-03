class NotifyWaitlistJob < ApplicationJob
  queue_as :default

  def perform
    return unless WaitlistEntry.pending.exists?
    return unless Slot.available
                      .where("starts_at >= ? AND starts_at < ?", Time.current, 30.days.from_now)
                      .exists?

    WaitlistEntry.pending.includes(:user).each do |entry|
      WaitlistMailer.slots_available(entry).deliver_later
      entry.notify!
    end
  end
end
