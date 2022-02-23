# frozen_string_literal: true

require "omniauth-oauth2"

module OmniAuth::Strategies
  class WorkOS < OmniAuth::Strategies::OAuth2
    class Error < StandardError
      attr_reader :code

      def initialize(code:, message:)
        @code = code
        super(message)
      end
    end

    AUTHORIZE_PARAMS_SESSION_KEY = "omniauth_workos_authorize_params"
    private_constant :AUTHORIZE_PARAMS_SESSION_KEY

    option :name, "workos"
    option :client_options,
           site: "https://api.workos.com",
           authorize_url: "/sso/authorize",
           token_url: "/sso/token"
    option :authorize_options, %w[organization connection provider login_hint]
    # info_fields:
    # Either an **array** with the names of the fields as **strings**, or the
    # the **string** "all" to return all available fields.
    option :info_fields, "all"

    uid do
      raw_info.fetch("id")
    end

    info do
      if options[:info_fields] == "all"
        raw_info.clone.tap { |hash| hash.delete("id") }
      else
        {}.tap do |result|
          options[:info_fields].each do |field|
            field = field.to_s
            result[field] = raw_info[field]
          end
        end
      end
    end

    credentials do
      {
        "token" => access_token.token,
        # As per the documentation, tokens expire in 10 minutes.
        "expires" => true,
        "expires_at" => Time.now.utc.to_i + (10 * 60)
      }.tap do
        authorize_params = session.delete(AUTHORIZE_PARAMS_SESSION_KEY) || {}

        # Confirm that the user comes from the connection/organization requested
        # during the authorize phase.
        unless authorize_params.key?("connection") || authorize_params.key?("organization")
          raise Error.new(code: :invalid_session,
                          message: "invalid session; no connection nor organization")
        end

        if authorize_params.key?("connection") && authorize_params["connection"] != raw_info["connection_id"]
          raise Error.new(code: :connection_mismatch,
                          message: "the user's connection_id `#{raw_info["connection_id"]}` doesn't match what was requested `#{authorize_params["connection"]}`")
        end

        if authorize_params.key?("organization") && authorize_params["organization"] != raw_info["organization_id"]
          raise Error.new(code: :organization_mismatch,
                          message: "the user's organization_id `#{raw_info["organization_id"]}` doesn't match what was requested `#{authorize_params["organization"]}`")
        end
      end
    end

    def authorize_params
      super.tap do |params|
        options[:authorize_options].each do |key|
          value = request.params[key]
          next if blank?(value)

          params[key] = value
        end

        # Store the authorize params in the session because we will need them
        # during the callback phase to verify that the user comes from the
        # requested connection/organization.
        session[AUTHORIZE_PARAMS_SESSION_KEY] = params
      end
    end

    def request_phase
      if blank?(options.client_id)
        fail!(:missing_client_id)
      elsif blank?(options.client_secret)
        fail!(:missing_client_secret)
      else
        super
      end
    end

    def callback_phase
      super
    rescue Error => e
      fail!(e.code, e)
    end

    private

    def raw_info
      @raw_info ||= access_token["profile"]
    end

    # https://github.com/omniauth/omniauth-oauth2/issues/93
    def callback_url
      full_host + script_name + callback_path
    end

    def blank?(obj)
      obj.respond_to?(:empty?) ? obj.empty? : !obj
    end
  end
end

OmniAuth.config.add_camelization "workos", "WorkOS"
