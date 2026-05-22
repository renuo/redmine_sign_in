ENV["RAILS_ENV"] = "test"

FAKE_REDMINE_CLIENT_ID     = "redmine-sign-in-test-client-id"
FAKE_REDMINE_CLIENT_SECRET = "redmine-sign-in-test-client-secret"
FAKE_REDMINE_HOST          = "https://redmine.example.com"

require_relative "../test/dummy/config/environment"

require "rails/test_help"
require "webmock/minitest"
