# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake"

group :development do
  gem "debug"
  gem "retest"
end

group :test do
  gem "rack-test", "~> 1.1"
  gem "rspec", "~> 3.11"
  gem "sinatra", "~> 2.2"
  gem "timecop", "~> 0.9"
  gem "webmock", "~> 3.14"
end

group :test, :development do
  gem "standard", "~> 1.7"
end
