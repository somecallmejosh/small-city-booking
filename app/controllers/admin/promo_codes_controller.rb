class Admin::PromoCodesController < Admin::BaseController
  include Pagy::Method

  before_action :set_promo_code, only: [ :show, :edit, :update, :destroy ]

  def index
    @pagy, @promo_codes = pagy(PromoCode.order(created_at: :desc), limit: 25)
  end

  def show
    @usages = @promo_code.promo_code_usages.includes(:user, :booking).order(created_at: :desc)
  end

  def new
    @promo_code = PromoCode.new(active: true)
  end

  def create
    @promo_code = PromoCode.new(promo_code_params)
    if @promo_code.save
      redirect_to admin_promo_code_path(@promo_code), notice: "Promo code created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @promo_code.update(promo_code_params)
      redirect_to admin_promo_code_path(@promo_code), notice: "Promo code updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @promo_code.destroy
      redirect_to admin_promo_codes_path, notice: "Promo code deleted."
    else
      redirect_to admin_promo_code_path(@promo_code),
                  alert: @promo_code.errors.full_messages.to_sentence
    end
  end

  private

    def set_promo_code
      @promo_code = PromoCode.find(params[:id])
    end

    def promo_code_params
      params.expect(promo_code: [ :name, :code, :discount_percent, :start_date, :end_date, :active ])
    end
end
