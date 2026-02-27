class BookingsController < ApplicationController
  def index
    @bookings = Current.user.bookings.includes(:slots).order(created_at: :desc)
  end

  def new
    @booking = Booking.pending.includes(:slots).find_by(
      id:   session[:pending_booking_id],
      user: Current.user
    )

    if @booking.nil? || @booking.slots.minimum(:held_until) < Time.current
      redirect_to root_path, alert: "Your hold has expired. Please select slots again."
      return
    end

    @agreement  = Agreement.current
    @held_until = @booking.slots.minimum(:held_until)
  end

  def create
    @booking = Booking.pending.includes(:slots).find_by(
      id:   session[:pending_booking_id],
      user: Current.user
    )

    if @booking.nil? || @booking.slots.minimum(:held_until) < Time.current
      redirect_to root_path, alert: "Your hold has expired. Please select slots again."
      return
    end

    agreement = Agreement.current

    checkout_session = Stripe::Checkout::Session.create(
      line_items: [ {
        price_data: {
          currency:     "usd",
          unit_amount:  @booking.total_cents,
          product_data: { name: "Studio Booking — #{@booking.slots.count} hour(s)" }
        },
        quantity: 1
      } ],
      mode:        "payment",
      success_url: booking_url(@booking),
      cancel_url:  new_booking_url,
      payment_intent_data: {
        metadata: {
          booking_id:     @booking.id,
          agreement_id:   agreement.id,
          agreed_ip:      request.remote_ip,
          agreed_user_agent: request.user_agent
        }
      }
    )

    @booking.update!(stripe_payment_link_id: checkout_session.id)

    redirect_to checkout_session.url, allow_other_host: true
  end

  def show
    @booking = Current.user.bookings.includes(:slots).find(params[:id])
  end

  def cancel
    @booking = Current.user.bookings.find(params[:id])

    unless @booking.status == "confirmed"
      redirect_to booking_path(@booking), alert: "Only confirmed bookings can be cancelled."
      return
    end

    if @booking.within_cancellation_window?
      Stripe::Refund.create(payment_intent: @booking.stripe_payment_intent_id)
      @booking.update!(refunded: true)
    end

    @booking.slots.each { |slot| slot.update!(status: "open") }
    @booking.update!(status: "cancelled", cancelled_at: Time.current)

    redirect_to bookings_path, notice: "Booking cancelled."
  end
end
