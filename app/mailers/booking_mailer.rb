class BookingMailer < ApplicationMailer
  STUDIO_ADDRESS = "123 Main St, Anytown, NY 10001"
  TIMEZONE       = "Eastern Time (US & Canada)"

  def confirmation(booking)
    @booking = booking
    @user    = booking.user
    @slots   = booking.slots.order(:starts_at)
    @total   = booking.total_cents / 100.0
    @receipt = booking.safe_receipt_url
    mail(to: @user.email_address, subject: "Your session is confirmed — Small City Studio")
  end

  def reminder(booking)
    @booking = booking
    @user    = booking.user
    @slots   = booking.slots.order(:starts_at)
    mail(to: @user.email_address, subject: "Your session is tomorrow — Small City Studio")
  end

  def follow_up(booking)
    @booking = booking
    @user    = booking.user
    mail(to: @user.email_address, subject: "How was your session? — Small City Studio")
  end
end
