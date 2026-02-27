class ManualBookingCreator
  Result = Struct.new(:success?, :booking, :error, keyword_init: true)

  def initialize(params)
    @user_id              = params[:user_id]
    @slot_ids             = Array(params[:slot_ids]).compact_blank.map(&:to_i)
    @notes                = params[:notes]
    @generate_payment_link = params[:generate_payment_link] == "1"
  end

  def call
    user = User.find_by(id: @user_id)
    return Result.new(success?: false, booking: nil, error: "Customer not found.") unless user

    slots = Slot.where(id: @slot_ids, status: "open")
    return Result.new(success?: false, booking: nil, error: "No available slots selected.") if slots.empty?

    agreement = Agreement.current
    return Result.new(success?: false, booking: nil, error: "No published agreement exists.") unless agreement

    total_cents = slots.count * StudioSetting.current.hourly_rate_cents

    booking = nil
    ActiveRecord::Base.transaction do
      booking = Booking.create!(
        user:          user,
        agreement:     agreement,
        status:        "confirmed",
        admin_created: true,
        total_cents:   total_cents,
        notes:         @notes.presence
      )

      slots.each do |slot|
        BookingSlot.create!(booking: booking, slot: slot)
        slot.update!(status: "reserved")
      end

      generate_payment_link!(booking, total_cents) if @generate_payment_link
    end

    Result.new(success?: true, booking: booking, error: nil)
  rescue => e
    Result.new(success?: false, booking: nil, error: e.message)
  end

  private

    def generate_payment_link!(booking, total_cents)
      price = Stripe::Price.create(
        currency:     "usd",
        unit_amount:  total_cents,
        product_data: { name: "Studio Booking ##{booking.id}" }
      )

      link = Stripe::PaymentLink.create(
        line_items: [ { price: price.id, quantity: 1 } ],
        metadata:   { booking_id: booking.id.to_s }
      )

      booking.update!(stripe_payment_link_id: link.id, stripe_payment_link_url: link.url)
    end
end
