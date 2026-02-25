class Admin::SettingsController < Admin::BaseController
  def show
    @settings = StudioSetting.current
  end

  def edit
    @settings = StudioSetting.current
  end

  def update
    @settings = StudioSetting.current

    if @settings.update(settings_params)
      redirect_to admin_settings_path, notice: "Settings updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def settings_params
      raw = params.expect(studio_setting: [ :hourly_rate, :studio_name, :studio_description, :cancellation_hours ])
      if raw[:hourly_rate].present?
        raw[:hourly_rate_cents] = (raw.delete(:hourly_rate).to_f * 100).round
      end
      raw
    end
end
