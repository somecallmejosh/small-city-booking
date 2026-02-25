FactoryBot.define do
  factory :push_subscription do
    association :user
    endpoint { "https://push.example.com/#{SecureRandom.hex(8)}" }
    p256dh { SecureRandom.base64(32) }
    auth { SecureRandom.base64(16) }
  end
end
