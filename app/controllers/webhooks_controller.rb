class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  allow_unauthenticated_access

  def stripe
    payload    = request.raw_post
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET"]
      )
    rescue Stripe::SignatureVerificationError
      head :bad_request
      return
    end

    case event.type
    when "payment_intent.succeeded"
      handle_payment_intent_succeeded(event.data.object)
    when "payment_intent.payment_failed"
      handle_payment_intent_failed(event.data.object)
    end

    head :ok
  end

  private

    def handle_payment_intent_succeeded(intent)
      booking = Booking.find_by(id: intent.metadata["booking_id"])
      return if booking.nil? || booking.status == "confirmed"

      if booking.slots.any? { |s| s.status != "held" || s.held_by_user_id != booking.user_id }
        Stripe::Refund.create(payment_intent: intent.id)
        booking.update!(status: "cancelled")
        return
      end

      booking.update!(status: "confirmed", stripe_payment_intent_id: intent.id)

      booking.slots.each do |slot|
        slot.update!(status: "reserved", held_by_user: nil, held_until: nil)
      end

      AgreementAcceptance.create!(
        user:       booking.user,
        agreement:  booking.agreement,
        booking:    booking,
        ip_address: intent.metadata["agreed_ip"],
        user_agent: intent.metadata["agreed_user_agent"],
        accepted_at: Time.current
      )
    end

    def handle_payment_intent_failed(intent)
      booking = Booking.find_by(id: intent.metadata["booking_id"])
      return unless booking

      booking.slots.each do |slot|
        slot.update!(status: "open", held_by_user: nil, held_until: nil)
      end
      booking.update!(status: "cancelled")
    end
end
