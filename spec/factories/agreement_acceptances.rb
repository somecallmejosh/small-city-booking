FactoryBot.define do
  factory :agreement_acceptance do
    association :user
    association :agreement
    association :booking
    ip_address { "127.0.0.1" }
    user_agent { "Mozilla/5.0" }
    accepted_at { Time.current }
  end
end
