# frozen_string_literal: true

require "rubygems/keychain"

require "rubygems/command_manager"
Gem::CommandManager.instance.register_command :keychain

require "rubygems/config_file"
unless Gem::ConfigFile.include? Gem::Keychain::ConfigFileExtensions
  Gem::ConfigFile.prepend(Gem::Keychain::ConfigFileExtensions)
end

require "rubygems/security"
unless Gem::Security::Signer.singleton_class.include? Gem::Keychain::SignerExtensions
  Gem::Security::Signer.singleton_class.prepend(Gem::Keychain::SignerExtensions)
end
