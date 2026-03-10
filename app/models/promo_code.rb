class PromoCode < ApplicationRecord
  has_many :promo_code_usages, dependent: :restrict_with_error
  has_many :users, through: :promo_code_usages

  before_validation :normalize_code

  validates :name,             presence: true
  validates :code,             presence: true, uniqueness: { case_sensitive: false }
  validates :discount_percent, presence: true,
                               numericality: { only_integer: true,
                                               greater_than_or_equal_to: 1,
                                               less_than_or_equal_to: 100 }
  validates :start_date, presence: true
  validates :end_date,   presence: true
  validate  :end_date_on_or_after_start_date
  validates :active, inclusion: { in: [ true, false ] }

  # Find a code by raw string input (case-insensitive)
  def self.find_by_code(raw_code)
    find_by(code: raw_code.to_s.strip.downcase)
  end

  # Returns true if this code can be applied to this user's booking.
  # Eligibility requires: active, not already used by user, and at least
  # one slot's start time (in Eastern Time) falls within [start_date, end_date].
  def eligible_for?(user, slots)
    return false unless active?
    return false if promo_code_usages.exists?(user: user)

    et_zone = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
    slots.any? do |slot|
      slot_date = slot.starts_at.in_time_zone(et_zone).to_date
      slot_date >= start_date && slot_date <= end_date
    end
  end

  # Returns the discount amount in cents (floored to avoid over-discounting).
  def discount_for(total_cents)
    (total_cents * discount_percent / 100.0).floor
  end

  private

    def normalize_code
      self.code = code.to_s.strip.downcase
    end

    def end_date_on_or_after_start_date
      return if start_date.blank? || end_date.blank?

      errors.add(:end_date, "must be on or after start date") if end_date < start_date
    end
end
