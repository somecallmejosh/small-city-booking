class WaitlistEntry < ApplicationRecord
  STATUSES = %w[pending notified].freeze

  belongs_to :user

  validates :status, inclusion: { in: STATUSES }

  scope :pending,  -> { where(status: "pending") }
  scope :notified, -> { where(status: "notified") }
  scope :ordered,  -> { order(created_at: :asc) }

  def notify!
    update!(status: "notified", notified_at: Time.current)
  end
end
