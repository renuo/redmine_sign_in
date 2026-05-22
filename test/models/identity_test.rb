require "test_helper"

class RedmineSignIn::IdentityTest < ActiveSupport::TestCase
  setup do
    @access_token = "redmine-access-token"
    @userinfo_url = "#{FAKE_REDMINE_HOST}/users/current.json"
  end

  test "userinfo_url must be set" do
    assert_raises ArgumentError do
      RedmineSignIn::Identity.new(@access_token, userinfo_url: nil).user_id
    end
  end

  test "raises FetchError on non-success response" do
    stub_userinfo status: 401, body: { error: "invalid_token" }

    assert_raises RedmineSignIn::Identity::FetchError do
      RedmineSignIn::Identity.new(@access_token).user_id
    end
  end

  test "raises FetchError on invalid JSON" do
    stub_request(:get, @userinfo_url)
      .with(headers: { "Authorization" => "Bearer #{@access_token}" })
      .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: "not-json")

    assert_raises RedmineSignIn::Identity::FetchError do
      RedmineSignIn::Identity.new(@access_token).user_id
    end
  end

  test "extracts user id" do
    stub_userinfo user: { id: 42, login: "georges", firstname: "George", lastname: "Claghorn", mail: "george@example.com" }

    assert_equal 42, RedmineSignIn::Identity.new(@access_token).user_id
  end

  test "extracts login" do
    stub_userinfo user: { id: 42, login: "georges" }

    assert_equal "georges", RedmineSignIn::Identity.new(@access_token).login
  end

  test "extracts email address from mail" do
    stub_userinfo user: { id: 42, mail: "george@example.com" }

    assert_equal "george@example.com", RedmineSignIn::Identity.new(@access_token).email_address
  end

  test "composes full name from firstname and lastname" do
    stub_userinfo user: { id: 42, firstname: "George", lastname: "Claghorn" }

    assert_equal "George Claghorn", RedmineSignIn::Identity.new(@access_token).name
  end

  test "extracts given and family names" do
    stub_userinfo user: { id: 42, firstname: "George", lastname: "Claghorn" }

    identity = RedmineSignIn::Identity.new(@access_token)
    assert_equal "George", identity.given_name
    assert_equal "Claghorn", identity.family_name
  end

  test "memoizes the userinfo response across attribute reads" do
    stub = stub_userinfo user: { id: 42, login: "georges", mail: "george@example.com" }

    identity = RedmineSignIn::Identity.new(@access_token)
    identity.user_id
    identity.login
    identity.email_address

    assert_requested stub, times: 1
  end

  test "accepts a custom userinfo_url override" do
    custom_url = "https://custom.redmine.example.com/users/current.json"
    stub_request(:get, custom_url)
      .with(headers: { "Authorization" => "Bearer #{@access_token}" })
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: JSON.generate(user: { id: 7, login: "custom" })
      )

    identity = RedmineSignIn::Identity.new(@access_token, userinfo_url: custom_url)
    assert_equal 7, identity.user_id
    assert_equal "custom", identity.login
  end

  private
    def stub_userinfo(status: 200, **body)
      stub_request(:get, @userinfo_url)
        .with(headers: { "Authorization" => "Bearer #{@access_token}" })
        .to_return(
          status: status,
          headers: { "Content-Type" => "application/json" },
          body: JSON.generate(body)
        )
    end
end
