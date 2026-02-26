class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @settings = StudioSetting.current

    # Lazy cleanup: release any expired holds before building the calendar.
    # HoldExpiryJob runs every minute, but this covers the gap between runs.
    Slot.where(status: "held").where("held_until < ?", Time.current)
        .find_each { |s| s.update!(status: "open", held_by_user: nil, held_until: nil) }

    @slots_by_date = Slot
      .where(status: %w[open held])
      .where("starts_at >= ? AND starts_at < ?", Time.current.beginning_of_day, 30.days.from_now)
      .order(:starts_at)
      .group_by { |s| s.starts_at.to_date }
  end
end
