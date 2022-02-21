# frozen_string_literal: true

require_relative "lib/omniauth-workos/version"

Gem::Specification.new do |spec|
  spec.name = "omniauth-workos"
  spec.version = OmniAuth::WorkOS::VERSION
  spec.authors = ["João Fernandes"]
  spec.email = ["joao.fernandes@ist.utl.pt"]

  spec.summary = "OmniAuth OAuth2 strategy for the WorkOS platform"
  spec.homepage = "https://github.com/jcmfernandes/omniauth-workos"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency 'omniauth', '~> 2.0'
  spec.add_dependency 'omniauth-oauth2', '~> 1.7'
end
