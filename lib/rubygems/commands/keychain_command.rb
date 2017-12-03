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
      list         list api keys by name/host
    EOF
  end

  def description # :nodoc:
  end

  def usage # :nodoc:
    "#{program_name} COMMAND"
  end

  def execute
    command = options[:args].shift
    case command
    when "import"
      import_command
    when "list"
      list_command
    else
      terminate_interaction(1)
    end
  end

  def import_command # :nodoc:
    if options[:args].any?
      credentials_path = options[:args].shift
    else
      credentials_path = Gem.configuration.credentials_path
    end

    unless File.exists?(credentials_path)
      alert_error("No credentials file found: #{credentials_path} does not exist")
      terminate_interaction(1)
    end

    existing_credentials = Gem.configuration.load_file(credentials_path)
    if existing_credentials.empty?
      alert_error("No api keys found: #{credentials_path} is empty")
      terminate_interaction(1)
    end

    say "Importing api keys from #{credentials_path}:"
    existing_credentials.each do |(key, value)|
      say " - #{key}"
      unless Gem::Keychain.set_api_key(host: key.to_s, key: value.to_s)
        alert_error("Couldn't import #{key}")
        terminate_interaction(1)
      end
    end
  end

  def list_command
    hosts = Gem::Keychain.list_api_keys
    if hosts.empty?
      alert "No api keys found in the Keychain"
      terminate_interaction
    end

    if hosts.delete("rubygems")
      say "- default (rubygems.org)"
    end

    hosts.sort.each do |host|
      say "- #{host}"
    end
  end
end
