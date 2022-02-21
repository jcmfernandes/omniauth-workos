# OmniAuth WorkOS Strategy

An OmniAuth strategy for authenticating with [WorkOS](https://workos.com). This strategy is based on the [OmniAuth OAuth2 strategy](https://github.com/omniauth/omniauth-oauth2).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-workos'
```

If you're using this strategy with Rails, also add the following for CSRF protection:

```ruby
gem 'omniauth-rails_csrf_protection'
```

And then execute:

    $ bundle install

## Usage

To start processing authentication requests, the following steps must be performed:

1. Initialize the strategy
2. Configure the callback controller
3. Add the required routes
4. Trigger an authentication request

### Authentication hash

The WorkOS strategy will provide the standard OmniAuth hash attributes:

- `:provider` - the name of the strategy, in this case `workos`
- `:uid` - the user identifier
- `:info` - the user's profile ([can be filtered](#filter-info-fields))
- `:credentials` - token requested and data

```ruby
{
  :provider => "workos",
  :uid => "prof_01DMC79VCBZ0NY2099737PSVF1",
  :info => {
    :connection_id => "conn_01E4ZCR3C56J083X43JQXF3JK5",
    :organization_id => "org_01EHWNCE74X7JSDV0X3SZ3KJNY",
    :connection_type => "okta",
    :email => "todd@foo-corp.com",
    :name => "Todd Rundgren",
    :first_name => "Todd",
    :idp_id => "00u1a0ufowBJlzPlk357",
    :last_name => "Rundgren",
    :object => "profile",
    :raw_attributes" => {...}
  },
  :credentials => {
    :token => "ACCESS_TOKEN",
    :expires_at => 1485373937,
    :expires => true
  }
}
```

#### Filter info fields

To filter the fields in the `info` object, you can specify them when you register the provider:

```ruby
provider
  :workos,
  ENV['WORKOS_CLIENT_ID'],
  ENV['WORKOS_CLIENT_SECRET'],
  ENV['WORKOS_DOMAIN'],
  {
    info_fields: %w[email first_name]
  }
```

Possible values are:
- `"all"` (default) - don't filter, that is, include all fields
- `%w[...]` (an array of **strings**) - the fields to include

Note: field `"name"` will always be included.

### Query parameter options

In some scenarios, you may need to pass specific query parameters to `/sso/authorize`. The following parameters are available to enable this:

- `connection`
- `organization`
- `provider`
- `login_hint`

Refer to the [documentation](https://workos.com/docs/reference/sso/authorize/get#authorize-get-endpoint) to see when and how to use them.

Simply pass these query parameters to your OmniAuth redirect endpoint to enable their behavior.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jcmfernandes/omniauth-workos.

## License

Released under the MIT License. See [{file:LICENSE}](LICENSE).

Copyright (c) 2022, João Fernandes

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
