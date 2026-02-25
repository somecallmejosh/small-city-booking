class Admin::DashboardController < Admin::BaseController
  def index
    @open_slots_count = Slot.where("starts_at >= ?", Time.current).open.count
    @reserved_slots_count = Slot.where("starts_at >= ?", Time.current).reserved.count
  end
end
