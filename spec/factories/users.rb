FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "securepassword1" }
    name { "Test User" }
    admin { false }

    trait :admin do
      admin { true }
      name { "Admin User" }
    end
  end
end
