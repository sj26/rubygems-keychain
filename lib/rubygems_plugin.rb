require "rubygems/command_manager"

Gem::CommandManager.instance.register_command :keychain

require "rubygems/config_file"
require "rubygems/keychain"

unless Gem::ConfigFile.include? Gem::Keychain::ConfigFileExtensions
  Gem::ConfigFile.prepend(Gem::Keychain::ConfigFileExtensions)
end
