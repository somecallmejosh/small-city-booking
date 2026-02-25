FactoryBot.define do
  factory :booking do
    association :user
    association :agreement
    status { "confirmed" }
    total_cents { 5000 }
    admin_created { false }
    refunded { false }
  end
end
