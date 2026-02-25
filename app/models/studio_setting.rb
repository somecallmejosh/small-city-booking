class StudioSetting < ApplicationRecord
  validates :hourly_rate_cents, presence: true, numericality: { greater_than: 0 }
  validates :cancellation_hours, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def self.current
    first_or_create!(
      hourly_rate_cents: 5000,
      studio_name: "Small City Studio",
      cancellation_hours: 24
    )
  end
end
