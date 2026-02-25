FactoryBot.define do
  factory :booking_slot do
    association :booking
    association :slot
  end
end
