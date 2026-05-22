require "test_helper"

class RedmineSignIn::CallbacksControllerTest < ActionDispatch::IntegrationTest
  test "receiving an authorization code" do
    post redmine_sign_in.authorization_url, params: { proceed_to: "http://www.example.com/login" }
    assert_response :redirect

    stub_token_for "auth-code-123", access_token: "redmine-access-token"

    get redmine_sign_in.callback_url(code: "auth-code-123", state: flash[:state])
    assert_redirected_to "http://www.example.com/login"
    assert_equal "redmine-access-token", flash[:redmine_sign_in][:access_token]
    assert_nil flash[:redmine_sign_in][:error]
    assert_nil flash[:state]
    assert_nil flash[:proceed_to]
  end

  %w[invalid_request unauthorized_client access_denied unsupported_response_type invalid_scope server_error temporarily_unavailable].each do |error|
    test "receiving an authorization code grant error: #{error}" do
      post redmine_sign_in.authorization_url, params: { proceed_to: "http://www.example.com/login" }
      assert_response :redirect

      get redmine_sign_in.callback_url(error: error, state: flash[:state])
      assert_redirected_to "http://www.example.com/login"
      assert_nil flash[:redmine_sign_in][:access_token]
      assert_equal error, flash[:redmine_sign_in][:error]
    end
  end

  test "receiving an invalid authorization error" do
    post redmine_sign_in.authorization_url, params: { proceed_to: "http://www.example.com/login" }
    assert_response :redirect

    get redmine_sign_in.callback_url(error: "unknown error code", state: flash[:state])
    assert_redirected_to "http://www.example.com/login"
    assert_nil flash[:redmine_sign_in][:access_token]
    assert_equal "invalid_request", flash[:redmine_sign_in][:error]
  end

  test "receiving neither code nor error" do
    post redmine_sign_in.authorization_url, params: { proceed_to: "http://www.example.com/login" }
    assert_response :redirect

    get redmine_sign_in.callback_url(state: flash[:state])
    assert_redirected_to "http://www.example.com/login"
    assert_nil flash[:redmine_sign_in][:access_token]
    assert_equal "invalid_request", flash[:redmine_sign_in][:error]
  end

  %w[invalid_request invalid_client invalid_grant unauthorized_client unsupported_grant_type invalid_scope].each do |error|
    test "receiving an access token request error: #{error}" do
      post redmine_sign_in.authorization_url, params: { proceed_to: "http://www.example.com/login" }
      assert_response :redirect

      stub_token_error_for "auth-code-123", error: error

      get redmine_sign_in.callback_url(code: "auth-code-123", state: flash[:state])
      assert_redirected_to "http://www.example.com/login"
      assert_nil flash[:redmine_sign_in][:access_token]
      assert_equal error, flash[:redmine_sign_in][:error]
    end
  end

  test "protecting against CSRF without flash state" do
    post redmine_sign_in.authorization_url, params: { proceed_to: "http://www.example.com/login" }
    assert_response :redirect

    get redmine_sign_in.callback_url(code: "auth-code-123", state: "invalid")
    assert_redirected_to "http://www.example.com/login"
    assert_nil flash[:redmine_sign_in][:access_token]
    assert_equal "invalid_request", flash[:redmine_sign_in][:error]
  end

  test "protecting against CSRF with invalid state" do
    post redmine_sign_in.authorization_url, params: { proceed_to: "http://www.example.com/login" }
    assert_response :redirect
    assert_not_nil flash[:state]

    get redmine_sign_in.callback_url(code: "auth-code-123", state: "invalid")
    assert_redirected_to "http://www.example.com/login"
    assert_nil flash[:redmine_sign_in][:access_token]
    assert_equal "invalid_request", flash[:redmine_sign_in][:error]
  end

  test "protecting against CSRF with missing state" do
    post redmine_sign_in.authorization_url, params: { proceed_to: "http://www.example.com/login" }
    assert_response :redirect
    assert_not_nil flash[:state]

    get redmine_sign_in.callback_url(code: "auth-code-123")
    assert_redirected_to "http://www.example.com/login"
    assert_nil flash[:redmine_sign_in][:access_token]
    assert_equal "invalid_request", flash[:redmine_sign_in][:error]
  end

  test "protecting against open redirects" do
    post redmine_sign_in.authorization_url, params: { proceed_to: "http://malicious.example.com/login" }
    assert_response :redirect

    get redmine_sign_in.callback_url(code: "auth-code-123", state: flash[:state])
    assert_response :bad_request
  end

  test "protecting against open redirects given a malformed URI" do
    post redmine_sign_in.authorization_url, params: { proceed_to: "http://www.example.com\n\r@\n\revil.example.org/login" }
    assert_response :redirect

    get redmine_sign_in.callback_url(code: "auth-code-123", state: flash[:state])
    assert_response :bad_request
  end

  test "rejects proceed_to paths if they are relative" do
    post redmine_sign_in.authorization_url, params: { proceed_to: "login" }
    assert_response :redirect

    get redmine_sign_in.callback_url(code: "auth-code-123", state: flash[:state])
    assert_response :bad_request
  end

  test "accepts proceed_to paths if they are absolute" do
    post redmine_sign_in.authorization_url, params: { proceed_to: "/login" }
    assert_response :redirect

    stub_token_for "auth-code-123", access_token: "redmine-access-token"

    get redmine_sign_in.callback_url(code: "auth-code-123", state: flash[:state])
    assert_redirected_to "http://www.example.com/login"
  end

  test "protecting against open redirects given a double-slash net path" do
    post redmine_sign_in.authorization_url, params: { proceed_to: "//evil.example.org" }
    assert_response :redirect

    get redmine_sign_in.callback_url(code: "auth-code-123", state: flash[:state])
    assert_response :bad_request
  end

  test "protecting against open redirects given a triple-slash net path" do
    post redmine_sign_in.authorization_url, params: { proceed_to: "///evil.example.org" }
    assert_response :redirect

    get redmine_sign_in.callback_url(code: "auth-code-123", state: flash[:state])
    assert_response :bad_request
  end

  test "receiving no proceed_to URL" do
    get redmine_sign_in.callback_url(code: "auth-code-123", state: "invalid")
    assert_response :bad_request
  end

  private
    def stub_token_for(code, **response_body)
      stub_token_request(code, status: 200, response: response_body.merge(token_type: "bearer"))
    end

    def stub_token_error_for(code, error:)
      stub_token_request(code, status: 400, response: { error: error })
    end

    def stub_token_request(code, status:, response:)
      stub_request(:post, "#{FAKE_REDMINE_HOST}/oauth/token").with(
        body: {
          grant_type: "authorization_code",
          code: code,
          client_id: FAKE_REDMINE_CLIENT_ID,
          client_secret: FAKE_REDMINE_CLIENT_SECRET,
          redirect_uri: "http://www.example.com/redmine_sign_in/callback"
        }
      ).to_return(
        status: status,
        headers: { "Content-Type" => "application/json" },
        body: JSON.generate(response)
      )
    end
end
