class Admin::BookingsController < Admin::BaseController
  include Pagy::Method

  def index
    scope = Booking.includes(:user, :slots).order(created_at: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    @status_filter = params[:status]
    @pagy, @bookings = pagy(scope, limit: 25)
  end

  def show
    @booking = Booking.includes(:user, :slots, :agreement).find(params[:id])
  end

  def cancel
    @booking = Booking.find(params[:id])

    unless %w[pending confirmed].include?(@booking.status)
      redirect_to admin_booking_path(@booking), alert: "This booking cannot be cancelled."
      return
    end

    cancel_booking!(@booking)
    notice = @booking.refunded? ? "Booking cancelled and refund issued." : "Booking cancelled."
    redirect_to admin_bookings_path, notice: notice
  end

  def bulk_cancel
    bookings = Booking.where(id: Array(params[:booking_ids]), status: %w[pending confirmed])
    bookings.each { |b| cancel_booking!(b) }
    redirect_to admin_bookings_path(status: params[:status_filter].presence),
                notice: "#{bookings.count} booking(s) cancelled."
  end

  def new
    @users = User.order(:name)
    @available_slots = Slot.where("starts_at >= ? AND status = 'open'", Time.current)
                           .order(:starts_at)
                           .limit(100)
  end

  def create
    result = ManualBookingCreator.new(booking_params).call

    if result.success?
      redirect_to admin_booking_path(result.booking), notice: "Booking created."
    else
      @users = User.order(:name)
      @available_slots = Slot.where("starts_at >= ? AND status = 'open'", Time.current)
                             .order(:starts_at)
                             .limit(100)
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  private

    def cancel_booking!(booking)
      if booking.status == "confirmed" && booking.stripe_payment_intent_id.present?
        refund = Stripe::Refund.create(payment_intent: booking.stripe_payment_intent_id)
        booking.update!(refunded: true, stripe_refund_id: refund.id)
      end
      booking.slots.each { |slot| slot.update!(status: "open") }
      booking.update!(status: "cancelled", cancelled_at: Time.current)
    end

    def booking_params
      params.expect(booking: [ :user_id, :notes, :generate_payment_link, { slot_ids: [] } ])
    end
end
