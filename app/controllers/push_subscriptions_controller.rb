class PushSubscriptionsController < ApplicationController
  def create
    data = JSON.parse(request.body.read)

    sub = PushSubscription.find_or_create_by!(
      user:     Current.user,
      endpoint: data["endpoint"]
    ) do |s|
      s.p256dh = data["p256dh"]
      s.auth   = data["auth"]
    end

    render json: { id: sub.id }, status: :created
  rescue JSON::ParserError
    head :bad_request
  end

  def destroy
    sub = Current.user.push_subscriptions.find_by(id: params[:id])
    sub&.destroy
    head :ok
  end
end
