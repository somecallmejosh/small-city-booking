require "openssl"

module StripeHelpers
  # Must match ENV["STRIPE_WEBHOOK_SECRET"] set in rails_helper
  TEST_WEBHOOK_SECRET = "whsec_test_secret"

  def stripe_webhook_payload(type:, data:)
    payload   = JSON.generate({ id: "evt_test_#{SecureRandom.hex(4)}", type:, data: { object: data } })
    timestamp = Time.now.to_i
    signed    = "#{timestamp}.#{payload}"
    # Stripe gem uses the full secret string (including whsec_ prefix) as the HMAC key
    signature = OpenSSL::HMAC.hexdigest("SHA256", TEST_WEBHOOK_SECRET, signed)
    {
      payload:,
      sig_header: "t=#{timestamp},v1=#{signature}"
    }
  end
end

RSpec.configure do |config|
  config.include StripeHelpers, type: :request
end
