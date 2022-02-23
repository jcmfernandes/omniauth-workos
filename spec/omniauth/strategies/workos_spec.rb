# frozen_string_literal: true

require "omniauth"
require "omniauth-workos"

OmniAuth.config.allowed_request_methods = [:get, :post]

RSpec.describe OmniAuth::Strategies::WorkOS do
  context "configuration" do
    let(:application) do
      lambda do
        [200, {}, ['Hello.']]
      end
    end
    let(:strategy) do
      described_class.new(
        application,
        "CLIENT_ID",
        "CLIENT_SECRET"
      )
    end

    describe 'client_options' do
      subject { strategy.client }

      it 'should have correct authorize path' do
        expect(subject.options[:authorize_url]).to eq('/sso/authorize')
      end

      it 'should have the correct token path' do
        expect(subject.options[:token_url]).to eq('/sso/token')
      end
    end

    describe 'options' do
      subject { strategy.options }

      it 'should have the correct client_id' do
        expect(subject[:client_id]).to eq("CLIENT_ID")
      end

      it 'should have the correct client secret' do
        expect(subject[:client_secret]).to eq("CLIENT_SECRET")
      end
    end
  end

  describe 'phases' do
    let(:options) { { client_id: 'CLIENT_ID', client_secret: "CLIENT_SECRET" } }

    before do
      @app = make_application(options)
    end

    describe 'authorize phase' do
      it "redirects to WorkOS' authorize URL and includes OAuth base params" do
        get "auth/workos"

        expect(last_response.status).to eq(302)
        redirect_url = last_response.headers['Location']
        expect(redirect_url).to start_with('https://api.workos.com/sso/authorize')
        expect(redirect_url).to have_query('response_type', 'code')
        expect(redirect_url).to have_query('state')
        expect(redirect_url).to have_query('client_id', "CLIENT_ID")
        expect(redirect_url).to have_query('redirect_uri')
      end

      it "doesn't including missing nor blank params" do
        get "auth/workos?connection=&provider="

        expect(last_response.status).to eq(302)
        redirect_url = last_response.headers['Location']
        expect(redirect_url).not_to have_query('connection')
        expect(redirect_url).not_to have_query('organization')
        expect(redirect_url).not_to have_query('provider')
        expect(redirect_url).not_to have_query('login_hint')
      end

      it 'redirects to the authorize URL with connection, organization, provider, and login hint' do
        get 'auth/workos?connection=abcd&organization=efgh&provider=xpto&login_hint=test@acme.org'

        expect(last_response.status).to eq(302)
        redirect_url = last_response.headers['Location']
        expect(redirect_url).to start_with('https://api.workos.com/sso/authorize')
        expect(redirect_url).to have_query('connection', 'abcd')
        expect(redirect_url).to have_query('organization', 'efgh')
        expect(redirect_url).to have_query('provider', 'xpto')
        expect(redirect_url).to have_query('login_hint', "test@acme.org")
      end

      context "error handling" do
        context "when client_id is missing" do
          let(:options) { super().merge(client_id: nil) }

          it 'fails' do
            get 'auth/workos'

            expect(last_response.status).to eq(302)
            redirect_url = last_response.headers['Location']
            expect(redirect_url).to fail_auth_with('missing_client_id')
          end
        end

        context "when client_secret is missing" do
          let(:options) { super().merge(client_secret: nil) }

          it 'fails when missing client_secret' do
            get 'auth/workos'

            expect(last_response.status).to eq(302)
            redirect_url = last_response.headers['Location']
            expect(redirect_url).to fail_auth_with('missing_client_secret')
          end
        end
      end
    end

    describe 'callback phase'do
      let(:oauth_response) do
        {
          access_token: "t123",
          profile: {
            id: "prof_01",
            connection_id: "conn_01",
            organization_id: "org_01",
            connection_type: "okta",
            email: "todd@foo-corp.com",
            first_name: "Todd",
            idp_id: "00u1",
            last_name: "Rundgren",
            object: "profile",
            raw_attributes: { a: "abc", b: "def" }
          }
        }
      end
      let(:rack_session) do
        {
          "omniauth_workos_authorize_params" => { "connection" => "conn_01" }
        }
      end

      def stub_auth(body)
        stub_request(:post, 'https://api.workos.com/sso/token')
          .to_return(
            headers: { 'Content-Type' => 'application/json' },
            body: MultiJson.encode(body)
          )
      end

      def trigger_callback
        get '/auth/workos/callback', { 'state' => "123" },
            'rack.session' => { 'omniauth.state' => "123" }.merge!(rack_session)
      end

      subject(:payload) do
        MultiJson.decode(last_response.body)
      end

      before do
        WebMock.reset!
        stub_auth(oauth_response)
        Timecop.freeze
        trigger_callback
      end

      after do
        Timecop.return
      end

      it 'to succeed' do
        expect(last_response.status).to eq(200)
      end

      it 'has credentials' do
        expect(subject["credentials"]["token"]).to eq("t123")
      end

      it 'states that token expires in 10 minutes' do
        expect(subject["credentials"]["expires"]).to eq(true)
        expect(subject["credentials"]["expires_at"]).to eq(Time.now.utc.to_i + (10 * 60))
      end

      it 'has basic values' do
        expect(subject['provider']).to eq('workos')
        expect(subject['uid']).to eq("prof_01")
      end

      context "with info_fields as 'all'" do
        let(:options) { { info_fields: "all" } }

        it "returns all fields under profile except 'id'" do
          expect(subject["info"]).not_to have_key("id")
          expected_info = {
            "connection_id" => "conn_01",
            "organization_id" => "org_01",
            "connection_type" => "okta",
            "email" => "todd@foo-corp.com",
            "first_name" => "Todd",
            "idp_id" => "00u1",
            "last_name" => "Rundgren",
            "name" => "Todd Rundgren",
            "object" => "profile",
            "raw_attributes" => { "a" => "abc", "b" => "def" }
          }
          expect(subject['info']).to eq(expected_info)
        end
      end

      context "with info_fields as an array of fields" do
        let(:options) { { info_fields: %w[email first_name last_name] } }

        it "returns all fields under profile except 'id'" do
          expected_info = {
            "email" => "todd@foo-corp.com",
            "first_name" => "Todd",
            "last_name" => "Rundgren",
            "name" => "Todd Rundgren"
          }
          expect(subject['info']).to eq(expected_info)
        end
      end

      context "error handling" do
        context "when can't find the connection nor organization IDs in the session" do
          let(:rack_session) { {} }

          it "fails" do
            expect(last_response.status).to eq(302)
            redirect_url = last_response.headers['Location']
            expect(redirect_url).to fail_auth_with('invalid_session')
          end
        end

        context "when the connection ID is in the session but it doesn't match what we got from WorkOS" do
          let(:rack_session) do
            {
              "omniauth_workos_authorize_params" => { "connection" => "invalid" }
            }
          end

          it "fails" do
            expect(last_response.status).to eq(302)
            redirect_url = last_response.headers['Location']
            expect(redirect_url).to fail_auth_with('connection_mismatch')
          end
        end

        context "when the organization ID is in the session but it doesn't match what we got from WorkOS" do
          let(:rack_session) do
            {
              "omniauth_workos_authorize_params" => { "organization" => "invalid" }
            }
          end

          it "fails" do
            expect(last_response.status).to eq(302)
            redirect_url = last_response.headers['Location']
            expect(redirect_url).to fail_auth_with('organization_mismatch')
          end
        end
      end
    end
  end
end

require "cgi"

RSpec::Matchers.define :fail_auth_with do |message|
  match do |actual|
    uri = URI(actual)
    query = CGI.parse(uri.query)
    (uri.path == '/auth/failure') &&
      (query['message'] == [message]) &&
      (query['strategy'] == ['workos'])
  end
end

RSpec::Matchers.define :have_query do |key, value|
  match do |actual|
    uri = redirect_uri(actual)
    query = query(uri)
    if value.nil?
      query.key?(key)
    else
      query[key] == [value]
    end
  end

  def redirect_uri(string)
    URI(string)
  end

  def query(uri)
    CGI.parse(uri.query)
  end
end
