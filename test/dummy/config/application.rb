require_relative "boot"

require "rails"
require "action_controller/railtie"
require "rails/test_unit/railtie"
require "redmine_sign_in"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.load_defaults 7.1
    config.eager_load = false
  end
end
