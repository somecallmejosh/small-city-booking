class PromoCodeUsage < ApplicationRecord
  belongs_to :promo_code
  belongs_to :user
  belongs_to :booking

  validates :promo_code_id, uniqueness: { scope: :user_id,
    message: "has already been used by this customer" }
end
