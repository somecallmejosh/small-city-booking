class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 5, within: 10.minutes, only: :create,
             with: -> { redirect_to new_registration_path, alert: "Too many sign-up attempts. Try again later." }

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.admin = false

    if @user.save
      RegistrationsMailer.verify_email(@user).deliver_later
      redirect_to new_session_path,
        notice: "Account created! Check your email to verify your address, then sign in."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

    def registration_params
      params.expect(user: [ :email_address, :password, :password_confirmation, :name ])
    end
end
