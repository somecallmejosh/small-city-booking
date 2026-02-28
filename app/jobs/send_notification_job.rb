class SendNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id, title, body, url: nil)
    user = User.find_by(id: user_id)
    return unless user

    payload = { title: title, options: { body: body, data: { path: url } } }.to_json

    user.push_subscriptions.each do |sub|
      WebPush.payload_send(
        message:  payload,
        endpoint: sub.endpoint,
        p256dh:   sub.p256dh,
        auth:     sub.auth,
        vapid: {
          subject:     "mailto:admin@smallcitystudio.com",
          public_key:  ENV["VAPID_PUBLIC_KEY"],
          private_key: ENV["VAPID_PRIVATE_KEY"]
        }
      )
    rescue WebPush::InvalidSubscription
      sub.destroy
    end
  end
end
