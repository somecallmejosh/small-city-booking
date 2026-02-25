class Slot < ApplicationRecord
  belongs_to :held_by_user, class_name: "User", optional: true
  has_many :booking_slots, dependent: :destroy
  has_many :bookings, through: :booking_slots

  STATUSES = %w[open held reserved cancelled].freeze

  validates :starts_at, presence: true
  validates :status, inclusion: { in: STATUSES }

  # Slots that are available for booking: either open, or held-but-expired (lazy cleanup).
  scope :available, -> {
    where("status = 'open' OR (status = 'held' AND held_until < ?)", Time.current)
  }

  scope :open, -> { where(status: "open") }
  scope :held, -> { where(status: "held") }
  scope :reserved, -> { where(status: "reserved") }
  scope :cancelled, -> { where(status: "cancelled") }

  def ends_at
    starts_at + 1.hour
  end

  def cancellable?
    status == "open"
  end
end
