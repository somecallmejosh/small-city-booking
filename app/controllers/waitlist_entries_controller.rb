class WaitlistEntriesController < ApplicationController
  def create
    entry = WaitlistEntry.find_or_initialize_by(user: Current.user)

    if entry.new_record?
      entry.status = "pending"
      entry.save!
      redirect_to root_path, notice: "You're on the waitlist. We'll email you when slots open up."
    elsif entry.status == "notified"
      entry.update!(status: "pending", notified_at: nil)
      redirect_to root_path, notice: "You've been added back to the waitlist."
    else
      redirect_to root_path, notice: "You're already on the waitlist."
    end
  end

  def destroy
    entry = WaitlistEntry.find_by(id: params[:id], user: Current.user)
    entry&.destroy
    redirect_to root_path, notice: "You've been removed from the waitlist."
  end
end
