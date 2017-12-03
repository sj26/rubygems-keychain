# frozen_string_literal: true

require "rubygems/command"
require "rubygems/keychain"

class Gem::Commands::KeychainCommand < Gem::Command
  def initialize
    super("keychain", "Manage RubyGems credentials in the macOS Keychain")
  end

  def arguments # :nodoc:
    <<~EOF
      import       import api keys from the default credentials file
      import FILE  import api keys from the specified credentials file
      list         list api key by names
    EOF
  end

  def description # :nodoc:
  end

  def usage # :nodoc:
    "#{program_name} keychain [command]"
  end

  def execute
    command = options[:args].shift
    case command
    when "import"
      import_command
    when "list"
      list_command
    else
      false
    end
  end

  def import_command # :nodoc:
    if options[:args].any?
      credentials_path = options[:args].shift
    else
      credentials_path = Gem.configuration.credentials_path
    end

    unless File.exists?(credentials_path)
      say "No credentials file found: #{credentials_path} does not exist"
      return false
    end

    existing_credentials = Gem.configuration.load_file(credentials_path)
    if existing_credentials.empty?
      say "No credentials found: #{credentials_path} is empty"
      return false
    end

    say "Importing api keys from #{credentials_path}:"
    existing_credentials.each do |(key, value)|
      say " - #{key}"
      unless Gem::Keychain.set_api_key(host: key.to_s, key: value.to_s)
        alert_error("Couldn't import #{key}")
        return false
      end
    end

    return true
  end

  def list_command
    hosts = Gem::Keychain.list_api_keys
    if hosts.empty?
      say "No api keys found in the Keychain"
    else
      if hosts.delete("rubygems")
        say "- default (rubygems.org)"
      end

      hosts.sort.each do |host|
        say "- #{host}"
      end
    end

    return true
  end
end
