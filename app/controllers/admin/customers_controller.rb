class Admin::CustomersController < Admin::BaseController
  include Pagy::Method

  def index
    customers = User.where(admin: false)
                    .left_joins(:bookings)
                    .group(:id)
                    .select("users.*, COUNT(bookings.id) AS bookings_count")

    if params[:q].present?
      q = "%#{params[:q].strip.downcase}%"
      customers = customers.where("LOWER(users.name) LIKE :q OR LOWER(users.email_address) LIKE :q", q: q)
    end

    customers = customers.order("users.name ASC NULLS LAST, users.email_address ASC")
    @pagy, @customers = pagy(customers, limit: 25)
  end

  def show
    @customer = User.where(admin: false).find(params[:id])
    @bookings = @customer.bookings.includes(:slots).order(created_at: :desc)
    @total_spent = @customer.bookings
                            .where(status: %w[confirmed completed])
                            .sum(:total_cents)
  end

  def edit
    @customer = User.where(admin: false).find(params[:id])
  end

  def update
    @customer = User.where(admin: false).find(params[:id])

    if @customer.update(customer_params)
      redirect_to admin_customer_path(@customer), notice: "Customer updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def customer_params
      params.expect(user: [ :name, :phone ])
    end
end
