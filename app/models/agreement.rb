class Agreement < ApplicationRecord
  has_rich_text :body
  has_many :bookings
  has_many :agreement_acceptances

  validates :version, presence: true, uniqueness: true
  validates :body, presence: true

  before_validation :set_next_version, on: :create

  scope :published, -> { where.not(published_at: nil).order(published_at: :desc) }

  def self.current
    published.first
  end

  private

  def set_next_version
    self.version = (Agreement.maximum(:version) || 0) + 1
  end
end
