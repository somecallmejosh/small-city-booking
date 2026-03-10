FactoryBot.define do
  factory :promo_code do
    sequence(:name)  { |n| "Promo #{n}" }
    sequence(:code)  { |n| "promo#{n}" }
    discount_percent { 20 }
    start_date       { Date.current - 7.days }
    end_date         { Date.current + 7.days }
    active           { true }

    trait :inactive do
      active { false }
    end

    trait :expired do
      start_date { Date.current - 30.days }
      end_date   { Date.current - 1.day }
    end

    trait :future do
      start_date { Date.current + 7.days }
      end_date   { Date.current + 14.days }
    end
  end
end
