class LoginsController < ApplicationController
  def create
    if (access_token = flash.dig(:redmine_sign_in, :access_token))
      identity = RedmineSignIn::Identity.new(access_token)
      render plain: "Signed in as #{identity.name} <#{identity.email_address}> (login: #{identity.login}, id: #{identity.user_id})"
    elsif (error = flash.dig(:redmine_sign_in, :error))
      render plain: "Authentication error: #{error}", status: :unauthorized
    else
      redirect_to root_path
    end
  end
end
