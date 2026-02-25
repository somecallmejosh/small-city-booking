FactoryBot.define do
  factory :slot do
    starts_at { 1.day.from_now.beginning_of_hour }
    status { "open" }
    held_by_user { nil }
    held_until { nil }

    trait :held do
      status { "held" }
      association :held_by_user, factory: :user
      held_until { 5.minutes.from_now }
    end

    trait :reserved do
      status { "reserved" }
    end

    trait :cancelled do
      status { "cancelled" }
    end
  end
end
