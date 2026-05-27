# Redmine Sign-In for Rails

Add Redmine sign-in to your Rails app. Lets users sign up for and sign in to your service with their Redmine accounts via OAuth 2.0.

Requires Redmine 7+ and Rails 7.1+.

## Alternatives

If you only need the OmniAuth strategy and want to wire up the controllers, callbacks, and routes yourself, 
a simpler version is available as a Gist:
- [OmniAuth Redmine strategy (Gist)](https://gist.github.com/sislr/fb7f6d8f05c96c199d9525706561902d)

## Installation

Add to your Gemfile:

```ruby
gem 'redmine_sign_in'
```

## Configuration

### 1. Register an OAuth application in Redmine

In Redmine, go to your account settings → **Applications** → **Register your application**. Set:

- **Name** — anything
- **Redirect URI** — `https://your-app.example.com/redmine_sign_in/callback`

For local development, register a separate application with `http://localhost:3000/redmine_sign_in/callback`.

Save and copy the resulting **client ID** and **client secret**.

### 2. Configure the gem

Run `bin/rails credentials:edit` and add:

```yaml
redmine_sign_in:
  host: https://redmine.example.com
  client_id: [Your client ID]
  client_secret: [Your client secret]
```

Or in an initializer:

```ruby
# config/initializers/redmine_sign_in.rb
Rails.application.configure do
  config.redmine_sign_in.host          = ENV['REDMINE_SIGN_IN_HOST']
  config.redmine_sign_in.client_id     = ENV['REDMINE_SIGN_IN_CLIENT_ID']
  config.redmine_sign_in.client_secret = ENV['REDMINE_SIGN_IN_CLIENT_SECRET']
end
```

`host` is the base URL of your Redmine instance (no trailing slash). The gem derives the authorize, token, and userinfo URLs from it:

- `#{host}/oauth/authorize`
- `#{host}/oauth/token`
- `#{host}/users/current.json`

You can override any of them with `config.redmine_sign_in.authorize_url`, `config.redmine_sign_in.token_url`, or `config.redmine_sign_in.userinfo_url`.

The callback mount point can be changed via `config.redmine_sign_in.root` (default: `redmine_sign_in`).

## Usage

The gem provides a `redmine_sign_in_button` helper:

```erb
<%= redmine_sign_in_button 'Sign in with Redmine', proceed_to: create_login_url %>
```

When using Hotwire/Turbo, disable Turbo on the button:

```erb
<%= redmine_sign_in_button 'Sign in with Redmine',
      proceed_to: create_login_url,
      data: { turbo: 'false' } %>
```

After authenticating, the gem redirects to `proceed_to` with either:

- `flash[:redmine_sign_in][:access_token]` — the Redmine OAuth access token, or
- `flash[:redmine_sign_in][:error]` — an [OAuth error code](https://tools.ietf.org/html/rfc6749#section-4.1.2.1).

A typical login controller:

```ruby
class LoginsController < ApplicationController
  def new
  end

  def create
    if user = authenticate_with_redmine
      cookies.signed[:user_id] = user.id
      redirect_to user
    else
      redirect_to new_session_url, alert: 'authentication_failed'
    end
  end

  private
    def authenticate_with_redmine
      if access_token = flash[:redmine_sign_in][:access_token]
        identity = RedmineSignIn::Identity.new(access_token)
        User.find_by(redmine_id: identity.user_id)
      elsif error = flash[:redmine_sign_in][:error]
        logger.error "Redmine authentication error: #{error}"
        nil
      end
    end
end
```

The `proceed_to` URL must be on the same origin as your app — this is enforced to prevent [open redirects](https://owasp.org/www-community/attacks/Unvalidated_Redirects_and_Forwards_Cheat_Sheet).

### `RedmineSignIn::Identity`

Wraps an access token and lazily fetches `/users/current.json` on first attribute read. Use `user_id` (the stable numeric Redmine user ID) to match against your own user records.

- `user_id` — Redmine's numeric user id. Stable; prefer over email.
- `login` — Redmine login handle.
- `email_address` — the user's `mail` field.
- `name` — full name (`firstname lastname`).
- `given_name` — `firstname`.
- `family_name` — `lastname`.

Raises `RedmineSignIn::Identity::FetchError` if Redmine returns a non-success response or invalid JSON.

## Development

```sh
bin/setup    # bundle install
bin/test     # run the test suite
bin/lint     # run rubocop
bin/dummy    # boot the test/dummy app at http://localhost:3000
```

The dummy app under `test/dummy` includes a welcome page (`/`) that renders
the `redmine_sign_in_button` helper, plus a `/login` endpoint that prints the
identity returned after the round-trip. Configure a real Redmine via env vars
before booting it:

```sh
REDMINE_SIGN_IN_HOST=https://redmine.example.com \
REDMINE_SIGN_IN_CLIENT_ID=... \
REDMINE_SIGN_IN_CLIENT_SECRET=... \
bin/dummy
```

## Credits

This gem is heavily inspired by
[basecamp/google_sign_in](https://github.com/basecamp/google_sign_in). The
engine layout, controller flow, flash-based handoff, and `RedirectProtector`
all follow that gem's design. The main departure is that Redmine's OAuth2
provider is not OIDC, so the flash carries an access token (not an ID token)
and `RedmineSignIn::Identity` fetches `/users/current.json` instead of
verifying a JWT locally.

## License

MIT.
