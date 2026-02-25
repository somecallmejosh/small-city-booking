class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :agreement
  has_many :booking_slots, dependent: :destroy
  has_many :slots, through: :booking_slots
  has_many :agreement_acceptances, dependent: :destroy

  STATUSES = %w[confirmed cancelled completed].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :total_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :confirmed, -> { where(status: "confirmed") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :completed, -> { where(status: "completed") }
  scope :upcoming, -> { joins(:slots).where("slots.starts_at > ?", Time.current).distinct }
  scope :past, -> { joins(:slots).where("slots.starts_at <= ?", Time.current).distinct }
end
