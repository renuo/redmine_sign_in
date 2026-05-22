Rails.application.configure do
  config.redmine_sign_in.client_id     = defined?(FAKE_REDMINE_CLIENT_ID)     ? FAKE_REDMINE_CLIENT_ID     : ENV.fetch("REDMINE_SIGN_IN_CLIENT_ID",     "dummy-client-id")
  config.redmine_sign_in.client_secret = defined?(FAKE_REDMINE_CLIENT_SECRET) ? FAKE_REDMINE_CLIENT_SECRET : ENV.fetch("REDMINE_SIGN_IN_CLIENT_SECRET", "dummy-client-secret")
  config.redmine_sign_in.host          = defined?(FAKE_REDMINE_HOST)          ? FAKE_REDMINE_HOST          : ENV.fetch("REDMINE_SIGN_IN_HOST",          "https://redmine.example.com")

  # Use :request_body auth scheme so test stubs can match body params.
  config.redmine_sign_in.oauth2_client_options = { auth_scheme: :request_body }
end
