require "active_support"
require "active_support/rails"
require "oauth2"

# Inspired by and structured after basecamp/google_sign_in
# (https://github.com/basecamp/google_sign_in).
module RedmineSignIn
  mattr_accessor :client_id
  mattr_accessor :client_secret
  mattr_accessor :host
  mattr_accessor :authorize_url
  mattr_accessor :token_url
  mattr_accessor :userinfo_url
  mattr_accessor :oauth2_client_options, default: nil

  # https://tools.ietf.org/html/rfc6749#section-4.1.2.1
  authorization_request_errors = %w[
    invalid_request
    unauthorized_client
    access_denied
    unsupported_response_type
    invalid_scope
    server_error
    temporarily_unavailable
  ]

  # https://tools.ietf.org/html/rfc6749#section-5.2
  access_token_request_errors = %w[
    invalid_request
    invalid_client
    invalid_grant
    unauthorized_client
    unsupported_grant_type
    invalid_scope
  ]

  OAUTH2_ERRORS = authorization_request_errors | access_token_request_errors

  def self.oauth2_client(redirect_uri:)
    OAuth2::Client.new \
      RedmineSignIn.client_id,
      RedmineSignIn.client_secret,
      authorize_url: RedmineSignIn.authorize_url,
      token_url: RedmineSignIn.token_url,
      redirect_uri: redirect_uri,
      **RedmineSignIn.oauth2_client_options.to_h
  end
end

require "redmine_sign_in/identity"
require "redmine_sign_in/engine" if defined?(Rails) && !defined?(RedmineSignIn::Engine)
