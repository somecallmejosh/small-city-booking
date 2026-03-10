FactoryBot.define do
  factory :booking do
    association :user
    association :agreement
    status { "confirmed" }
    total_cents { 5000 }
    discount_cents { 0 }
    admin_created { false }
    refunded { false }
    promo_code { nil }
  end
end
