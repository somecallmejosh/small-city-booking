class WaitlistMailer < ApplicationMailer
  def slots_available(waitlist_entry)
    @user = waitlist_entry.user
    mail(subject: "Studio slots are available — Small City Studio", to: @user.email_address)
  end
end
