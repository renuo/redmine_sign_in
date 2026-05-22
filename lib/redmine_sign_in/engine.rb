require "rails/engine"
require "redmine_sign_in" unless defined?(RedmineSignIn)

module RedmineSignIn
  class Engine < ::Rails::Engine
    isolate_namespace RedmineSignIn

    config.redmine_sign_in = ActiveSupport::OrderedOptions.new

    initializer "redmine_sign_in.config" do |app|
      config.after_initialize do
        credentials = app.credentials.redmine_sign_in || {}

        RedmineSignIn.client_id     = config.redmine_sign_in.client_id     || credentials[:client_id]
        RedmineSignIn.client_secret = config.redmine_sign_in.client_secret || credentials[:client_secret]
        RedmineSignIn.host          = config.redmine_sign_in.host          || credentials[:host]

        if RedmineSignIn.host.present?
          host = RedmineSignIn.host.chomp("/")
          RedmineSignIn.authorize_url = config.redmine_sign_in.authorize_url || "#{host}/oauth/authorize"
          RedmineSignIn.token_url     = config.redmine_sign_in.token_url     || "#{host}/oauth/token"
          RedmineSignIn.userinfo_url  = config.redmine_sign_in.userinfo_url  || "#{host}/users/current.json"
        else
          RedmineSignIn.authorize_url = config.redmine_sign_in.authorize_url
          RedmineSignIn.token_url     = config.redmine_sign_in.token_url
          RedmineSignIn.userinfo_url  = config.redmine_sign_in.userinfo_url
        end

        RedmineSignIn.oauth2_client_options = config.redmine_sign_in.oauth2_client_options
      end
    end

    config.to_prepare do
      ActionController::Base.helper RedmineSignIn::Engine.helpers
    end

    initializer "redmine_sign_in.mount" do |app|
      app.routes.prepend do
        mount RedmineSignIn::Engine, at: app.config.redmine_sign_in.root || "redmine_sign_in"
      end
    end

    initializer "redmine_sign_in.parameter_filters" do |app|
      app.config.filter_parameters << :code
    end
  end
end
