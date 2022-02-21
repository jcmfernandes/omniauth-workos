# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'rack/test'
require 'webmock/rspec'
require 'omniauth'
require 'sinatra'
require "multi_json"
require "logger"
require "timecop"

begin
  require "debug" unless ENV["CI"]
rescue LoadError
  # ignore
end

RSpec.configure do |config|
  config.include WebMock::API
  config.include Rack::Test::Methods
  config.extend OmniAuth::Test::StrategyMacros, type: :strategy

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_when_matching :focus

  config.example_status_persistence_file_path = "spec/examples.txt"

  config.disable_monkey_patching!

  # This setting enables warnings. It's recommended, but in some cases may
  # be too noisy due to issues in dependencies.
  # config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 10

  config.order = :random
  Kernel.srand config.seed

  def app
    @app || make_application
  end

  def make_application(options = {})
    client_id = options.key?(:client_id) ? options.delete(:client_id) : 'CLIENT_ID'
    client_secret = options.key?(:client_secret) ? options.delete(:client_secret) : 'CLIENT_SECRET'

    Sinatra.new do
      configure do
        enable :sessions
        set :show_exceptions, false
        set :session_secret, 'TEST'
      end

      use OmniAuth::Builder do
        provider :workos, client_id, client_secret, options
      end

      get '/auth/workos/callback' do
        MultiJson.encode(env['omniauth.auth'])
      end
    end
  end
end

OmniAuth.config.logger = Logger.new('/dev/null')
