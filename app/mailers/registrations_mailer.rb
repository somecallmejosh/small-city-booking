class RegistrationsMailer < ApplicationMailer
  def verify_email(user)
    @user  = user
    @token = user.generate_token_for(:email_verification)
    mail subject: "Verify your email — Small City Studio", to: user.email_address
  end
end
