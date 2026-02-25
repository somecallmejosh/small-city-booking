class AgreementAcceptance < ApplicationRecord
  belongs_to :user
  belongs_to :agreement
  belongs_to :booking

  validates :accepted_at, presence: true
end
