require "capybara/rspec"
require "capybara/cuprite"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [ 1200, 800 ], headless: true)
end

Capybara.javascript_driver = :cuprite
Capybara.default_driver    = :rack_test   # fast default; use :cuprite in JS-requiring specs
Capybara.default_max_wait_time = 5
