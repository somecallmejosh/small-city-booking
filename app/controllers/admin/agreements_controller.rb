class Admin::AgreementsController < Admin::BaseController
  def show
    @agreement = Agreement.current
    @archived  = Agreement.published.offset(1).limit(20)
  end

  def edit
    @agreement = Agreement.current
  end

  def update
    @agreement = Agreement.new(
      body:         agreement_params[:body],
      published_at: Time.current
    )

    if @agreement.save
      redirect_to admin_agreement_path, notice: "New agreement version #{@agreement.version} published."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def agreement_params
      params.expect(agreement: [ :body ])
    end
end
