class SlotHoldsController < ApplicationController
  def create
    slot_ids = Array(params[:slot_ids]).map(&:to_i).uniq

    if slot_ids.empty?
      redirect_to root_path, alert: "Please select at least one slot."
      return
    end

    booking = nil

    ActiveRecord::Base.transaction do
      locked = Slot.where(id: slot_ids).lock("FOR UPDATE SKIP LOCKED").to_a

      unless locked.size == slot_ids.size && locked.all? { |s| s.status == "open" }
        raise ActiveRecord::Rollback
      end

      rate_cents = StudioSetting.current.hourly_rate_cents
      agreement  = Agreement.current

      booking = Booking.create!(
        user:        Current.user,
        agreement:   agreement,
        status:      "pending",
        total_cents: slot_ids.size * rate_cents
      )

      locked.each do |slot|
        slot.update!(status: "held", held_by_user: Current.user, held_until: 2.minutes.from_now)
        BookingSlot.create!(booking: booking, slot: slot)
      end
    end

    if booking
      session[:pending_booking_id] = booking.id
      redirect_to new_booking_path
    else
      redirect_to root_path, alert: "One or more slots are no longer available. Please try again."
    end
  end

  def destroy
    booking = Booking.pending.find_by(id: session[:pending_booking_id], user: Current.user)

    if booking
      booking.slots.each do |slot|
        slot.update!(status: "open", held_by_user: nil, held_until: nil)
      end
      booking.update!(status: "cancelled")
      session.delete(:pending_booking_id)
    end

    redirect_to root_path
  end
end
