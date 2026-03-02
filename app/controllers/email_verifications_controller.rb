class EmailVerificationsController < ApplicationController
  allow_unauthenticated_access

  def show
    @user = User.find_by_token_for!(:email_verification, params[:token])

    if @user.email_verified?
      redirect_to new_session_path, notice: "Email already verified. Please sign in."
      return
    end

    @user.verify!
    start_new_session_for @user
    redirect_to root_path, notice: "Email verified! Welcome to Small City Studio."
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_email_verification_path,
      alert: "That verification link is invalid or has expired. Request a new one below."
  end

  def new
    # Renders the resend form
  end

  def create
    user = User.find_by(email_address: params[:email_address].to_s.strip.downcase)
    RegistrationsMailer.verify_email(user).deliver_later if user && !user.email_verified?

    redirect_to new_session_path,
      notice: "If that address is on file and unverified, we've sent a new verification link."
  end
end
