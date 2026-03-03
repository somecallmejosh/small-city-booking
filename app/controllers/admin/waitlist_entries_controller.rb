class Admin::WaitlistEntriesController < Admin::BaseController
  include Pagy::Method

  def index
    @pagy, @waitlist_entries = pagy(WaitlistEntry.includes(:user).ordered, limit: 25)
  end

  def destroy
    WaitlistEntry.find(params[:id]).destroy
    redirect_to admin_waitlist_entries_path, notice: "Waitlist entry removed."
  end
end
