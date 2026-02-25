FactoryBot.define do
  factory :agreement do
    body { "These are the terms of booking." }
    published_at { Time.current }
  end
end
