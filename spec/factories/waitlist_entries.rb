FactoryBot.define do
  factory :waitlist_entry do
    association :user
    status { "pending" }

    trait :notified do
      status { "notified" }
      notified_at { Time.current }
    end
  end
end
