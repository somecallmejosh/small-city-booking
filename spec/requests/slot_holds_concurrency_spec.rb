require "rails_helper"

# Concurrency spec: two threads race to hold the same slot.
# Uses DatabaseCleaner with :truncation to ensure data is visible across threads/connections.
RSpec.describe "SlotHolds concurrency", type: :request do
  before(:all) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end

  after(:all) do
    DatabaseCleaner.clean
    DatabaseCleaner.strategy = :transaction
  end

  it "only one thread wins the hold when two race for the same slot" do
    agreement = FactoryBot.create(:agreement)
    slot      = FactoryBot.create(:slot, status: "open")
    user1     = FactoryBot.create(:user, email_address: "concurrent1@example.com")
    user2     = FactoryBot.create(:user, email_address: "concurrent2@example.com")

    results   = Queue.new
    barrier   = Concurrent::CyclicBarrier.new(2) rescue nil

    threads = [ user1, user2 ].map do |u|
      Thread.new do
        # Each thread gets its own app session
        sess = ActionDispatch::Integration::Session.new(Rails.application)
        sess.post(
          "/session",
          params: { email_address: u.email_address, password: "securepassword1" }
        )

        # Synchronize so both threads POST at the same time
        barrier&.await(5) rescue nil

        sess.post(
          "/slot_holds",
          params: { slot_ids: [ slot.id ] }
        )
        results << sess.response.location
      end
    end

    threads.each { |t| t.join(10) }

    # Exactly 1 slot should be held
    expect(Slot.find(slot.id).status).to eq("held")
    # Exactly 1 pending booking should exist
    expect(Booking.where(status: "pending").count).to eq(1)
  end
end
