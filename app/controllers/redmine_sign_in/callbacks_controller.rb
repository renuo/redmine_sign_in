require "redmine_sign_in/redirect_protector"

class RedmineSignIn::CallbacksController < RedmineSignIn::BaseController
  def show
    redirect_to proceed_to_url, flash: { redmine_sign_in: redmine_sign_in_response }
    clear_redeemed_flash_keys if valid_request?
  rescue RedmineSignIn::RedirectProtector::Violation => error
    logger.error error.message
    head :bad_request
  end

  private
    def proceed_to_url
      flash[:proceed_to].tap { |url| RedmineSignIn::RedirectProtector.ensure_same_origin(url, request.url) }
    end

    def redmine_sign_in_response
      if valid_request? && params[:code].present?
        { access_token: access_token }
      else
        { error: error_message_for(params[:error]) }
      end
    rescue OAuth2::Error => error
      { error: error_message_for(error.code) }
    end

    def valid_request?
      flash[:state].present? && params[:state] == flash[:state]
    end

    def access_token
      client.auth_code.get_token(params[:code]).token
    end

    def error_message_for(error_code)
      error_code.presence_in(RedmineSignIn::OAUTH2_ERRORS) || "invalid_request"
    end

    def clear_redeemed_flash_keys
      flash.delete(:proceed_to)
      flash.delete(:state)
    end
end
