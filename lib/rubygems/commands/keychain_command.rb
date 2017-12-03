# frozen_string_literal: true

require "rubygems/command"
require "rubygems/keychain"

class Gem::Commands::KeychainCommand < Gem::Command
  def initialize
    super("keychain", "Manage RubyGems credentials in the macOS Keychain")
  end

  def arguments # :nodoc:
    <<~EOF
      import  import api keys from the credentials file
    EOF
  end

  def description # :nodoc:
  end

  def usage # :nodoc:
    "#{program_name} keychain [command]"
  end

  def execute
    command = options[:args][0]
    case command
    when "import"
      import_command
    else
      false
    end
  end

  def import_command # :nodoc:
    credentials_path = Gem.configuration.credentials_path
    unless File.exists?(credentials_path)
      say "No credential file found: #{Gem.configuration.credentials_path} does not exist"
      return false
    end

    existing_credentials = Gem.configuration.load_file(Gem.configuration.credentials_path)
    if existing_credentials.empty?
      say "No credentials found:  #{credentials_path} is empty"
      return false
    end

    say "Importing credentials:"
    existing_credentials.each do |(key, value)|
      say " - #{key}"
      unless Gem::Keychain.set_api_key(host: key.to_s, key: value.to_s)
        alert_error("Couldn't import #{key}")
        return false
      end
    end
    say "Done."

    return true
  end
end
