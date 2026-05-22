# Changelog

## 0.1.0

- Initial release. OAuth 2.0 authorization-code flow against a Redmine OAuth2
  provider (Redmine 7+). Lazy `RedmineSignIn::Identity` fetches 
  `/users/current.json` with the issued access token.
- Inspired by and structured after
  [basecamp/google_sign_in](https://github.com/basecamp/google_sign_in).
