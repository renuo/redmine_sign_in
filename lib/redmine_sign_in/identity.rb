require "net/http"
require "json"
require "uri"

module RedmineSignIn
  class Identity
    class FetchError < StandardError; end

    def initialize(access_token, userinfo_url: RedmineSignIn.userinfo_url)
      @access_token = access_token
      @userinfo_url = userinfo_url
    end

    def user_id
      payload["id"]
    end

    def login
      payload["login"]
    end

    def email_address
      payload["mail"]
    end

    def name
      [ payload["firstname"], payload["lastname"] ].compact.join(" ")
    end

    def given_name
      payload["firstname"]
    end

    def family_name
      payload["lastname"]
    end

    private
      def payload
        @payload ||= fetch_payload
      end

      def fetch_payload
        if @userinfo_url.blank?
          raise ArgumentError, "RedmineSignIn.userinfo_url (or RedmineSignIn.host) must be set to fetch identity"
        end

        uri = URI(@userinfo_url)
        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{@access_token}"
        request["Accept"] = "application/json"

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        unless response.is_a?(Net::HTTPSuccess)
          raise FetchError, "Failed to fetch Redmine user from #{@userinfo_url}: #{response.code} #{response.message}"
        end

        body = JSON.parse(response.body)
        body["user"] || body
      rescue JSON::ParserError => error
        raise FetchError, "Invalid JSON response from #{@userinfo_url}: #{error.message}"
      end
  end
end
