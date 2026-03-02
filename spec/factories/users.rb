FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "securepassword1" }
    name { "Test User" }
    admin { false }
    email_verified_at { nil }

    trait :verified do
      email_verified_at { Time.current }
    end

    trait :admin do
      admin { true }
      name { "Admin User" }
      email_verified_at { Time.current }
    end
  end
end
