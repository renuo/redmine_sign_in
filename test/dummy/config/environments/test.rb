Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false

  config.public_file_server.enabled = true
  config.public_file_server.headers = { "Cache-Control" => "public, max-age=3600" }

  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.action_dispatch.show_exceptions = :rescuable

  config.action_controller.allow_forgery_protection = false

  config.active_support.deprecation = :stderr

  config.secret_key_base = "redmine_sign_in_test_secret_key_base"
end
