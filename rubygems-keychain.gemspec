lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rubygems/keychain/version"

Gem::Specification.new do |spec|
  spec.name          = "rubygems-keychain"
  spec.version       = Gem::Keychain::VERSION
  spec.platform      = "x86_64-darwin"
  spec.author        = "Samuel Cochran"
  spec.email         = "sj26@sj26.com"

  spec.summary       = %q{Store your rubygems credentials and signing certificate in macOS keychain}
  spec.description   = %q{Store your rubygems credentials and signing certificate in macOS keychain}
  spec.homepage      = "https://github.com/sj26/rubygems-keychain"
  spec.license       = "MIT"

  spec.files         = Dir["README.md", "LICENSE", "lib/**/*.rb", "Helper.app/**/*"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
