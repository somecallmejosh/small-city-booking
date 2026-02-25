class Admin::SlotsController < Admin::BaseController
  include Pagy::Method

  def index
    @pagy, @slots = pagy(
      Slot.where("starts_at >= ?", Time.current).order(:starts_at),
      limit: 50
    )
  end

  def new
    @slot = Slot.new(starts_at: Time.current.beginning_of_hour + 1.hour)
  end

  def create
    @slot = Slot.new(slot_params.merge(status: "open"))
    if @slot.save
      redirect_to admin_slots_path, notice: "Slot created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def bulk_new; end

  def bulk_create
    result = BulkSlotCreator.new(
      days_of_week: Array(params[:days_of_week]).compact_blank,
      start_date:   Date.parse(params[:start_date]),
      end_date:     Date.parse(params[:end_date]),
      start_hour:   params[:start_hour],
      end_hour:     params[:end_hour]
    ).call

    msg = "Created #{result.created_count} slot(s)"
    msg += ", skipped #{result.skipped_count} duplicate(s)" if result.skipped_count > 0
    msg += ". #{result.errors.join('; ')}" if result.errors.any?

    redirect_to admin_slots_path, notice: msg
  end

  def destroy
    @slot = Slot.find(params[:id])
    if @slot.cancellable?
      @slot.update!(status: "cancelled")
      redirect_to admin_slots_path, notice: "Slot cancelled."
    else
      redirect_to admin_slots_path, alert: "Cannot cancel a #{@slot.status} slot. Cancel the booking first."
    end
  end

  private

    def slot_params
      params.expect(slot: [ :starts_at ])
    end
end
