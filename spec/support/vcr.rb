require "vcr"

VCR.configure do |c|
  c.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.filter_sensitive_data("<STRIPE_SECRET>") { ENV["STRIPE_SECRET_KEY"] }
  c.ignore_localhost = true
end
