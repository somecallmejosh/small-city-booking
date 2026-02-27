class HoldExpiryJob < ApplicationJob
  queue_as :default

  def perform
    Slot.where(status: "held").where("held_until < ?", Time.current).find_each do |slot|
      slot.update!(status: "open", held_by_user: nil, held_until: nil)
    end
  end
end
