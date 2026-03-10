FactoryBot.define do
  factory :promo_code_usage do
    association :promo_code
    association :user
    association :booking
  end
end
