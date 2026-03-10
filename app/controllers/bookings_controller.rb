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

  def apply_promo
    @booking = Booking.pending.includes(:slots).find_by(
      id:   session[:pending_booking_id],
      user: Current.user
    )

    if @booking.nil? || @booking.slots.minimum(:held_until) < Time.current
      redirect_to root_path, alert: "Your hold has expired. Please select slots again."
      return
    end

    raw_code = params[:promo_code].to_s.strip

    if raw_code.blank?
      @booking.update!(promo_code: nil, discount_cents: 0)
    else
      promo = PromoCode.find_by_code(raw_code)

      if promo&.eligible_for?(Current.user, @booking.slots.to_a)
        discount = promo.discount_for(@booking.total_cents)

        if discount > 0 && (@booking.total_cents - discount) < 50
          @promo_error = "This code would reduce your total below the minimum charge. Please contact the studio."
          @booking.update!(promo_code: nil, discount_cents: 0)
        else
          @booking.update!(promo_code: promo, discount_cents: discount)
          @promo_success = "#{promo.discount_percent}% discount applied!"
        end
      else
        @booking.update!(promo_code: nil, discount_cents: 0)
        @promo_error = "Code is invalid, expired, or has already been used."
      end
    end

    render turbo_stream: [
      turbo_stream.update("promo_section",
        partial: "bookings/promo_form",
        locals: { booking: @booking, promo_error: @promo_error, promo_success: @promo_success }),
      turbo_stream.update("total_section",
        partial: "bookings/total_display",
        locals: { booking: @booking })
    ]
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

    # Re-validate promo code eligibility before charging
    if @booking.promo_code.present?
      unless @booking.promo_code.eligible_for?(Current.user, @booking.slots.to_a)
        @booking.update!(promo_code: nil, discount_cents: 0)
        redirect_to new_booking_path, alert: "Your promo code is no longer valid. Please review your total."
        return
      end
    end

    agreement = Agreement.current

    checkout_session = Stripe::Checkout::Session.create(
      line_items: [ {
        price_data: {
          currency:     "usd",
          unit_amount:  @booking.charged_cents,
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

    if @booking.stripe_payment_intent_id.present?
      if @booking.within_cancellation_window?
        refund = Stripe::Refund.create(
          payment_intent: @booking.stripe_payment_intent_id,
          amount:         @booking.charged_cents
        )
      else
        refund_amount = @booking.charged_cents - 5000
        if refund_amount > 0
          refund = Stripe::Refund.create(
            payment_intent: @booking.stripe_payment_intent_id,
            amount:         refund_amount
          )
        end
      end
      @booking.update!(refunded: true, stripe_refund_id: refund.id) if refund
    end

    @booking.slots.each { |slot| slot.update!(status: "open") }
    @booking.update!(status: "cancelled", cancelled_at: Time.current)
    NotifyWaitlistJob.perform_later

    SendNotificationJob.perform_later(
      Current.user.id,
      "Booking Cancelled",
      "Your booking has been cancelled."
    )
    admin = admin_user
    if admin
      slot_label = @booking.slots.minimum(:starts_at)
                            .in_time_zone("Eastern Time (US & Canada)")
                            .strftime("%b %-d at %-I:%M %p")
      SendNotificationJob.perform_later(
        admin.id,
        "Booking Cancelled",
        "#{Current.user.name} cancelled their booking on #{slot_label}.",
        url: "/admin/bookings/#{@booking.id}"
      )
    end

    redirect_to bookings_path, notice: "Booking cancelled."
  end
end
