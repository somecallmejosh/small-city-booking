FactoryBot.define do
  factory :studio_setting do
    hourly_rate_cents { 5000 }
    studio_name { "Small City Studio" }
    studio_description { "A professional recording studio." }
    cancellation_hours { 24 }
  end
end
