require "simplecov"
SimpleCov.start "rails" do
  add_filter "/spec/"
  # ActionCable connection requires a live WebSocket; excluded from coverage requirement
  add_filter "/app/channels/"
  minimum_coverage 95
end

require "spec_helper"
ENV["RAILS_ENV"]              ||= "test"
ENV["STRIPE_SECRET_KEY"]      ||= "sk_test_fake"
ENV["STRIPE_WEBHOOK_SECRET"]  ||= "whsec_test_secret"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods

  # ViewComponent test helpers for component specs
  config.include ViewComponent::TestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component
end
