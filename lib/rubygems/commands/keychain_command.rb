# frozen_string_literal: true

require "rubygems/command"
require "rubygems/keychain"

class Gem::Commands::KeychainCommand < Gem::Command
  def initialize
    super "keychain",
      "Manage RubyGems api keys and signing certificates in the macOS Keychain",
      force: false

    add_option "-f", "--force", "For rm, forces removal without confirmation" do
      options[:force] = true
    end
  end

  def arguments # :nodoc:
    <<~EOF
      import
        import api keys from the default credentials file
      import FILE
        import api keys from the specified credentials file
      list
        list api keys by name/host
      add [host [key]]
        add api key for name/host
      rm [--force] [host]
        rm api key for name/host
    EOF
  end

  def usage # :nodoc:
    "#{program_name} COMMAND"
  end

  def execute
    command = options[:args].shift
    case command
    when nil, "help"
      show_help
    when "import"
      import_command
    when "list"
      list_command
    when "add"
      add_command
    when "rm"
      rm_command
    else
      alert_error "Unknown subcommand: #{command}. See '#{program_name} --help'."
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

    # stringify keys
    existing_credentials.keys.each do |key|
      if key.is_a? Symbol
        existing_credentials[key.to_s] = existing_credentials.delete(key)
      end
    end

    say "Importing api keys from #{credentials_path}:"

    # Make sure rubygems is always at the top
    if rubygems_key = (existing_credentials.delete("rubygems_api_key") || existing_credentials.delete("rubygems"))
      say " - rubygems (rubygems.org)"
      Gem::Keychain.set_api_key(key: rubygems_key.to_s)
    end

    existing_credentials.each do |(host, key)|
      say " - #{host}"
      Gem::Keychain.set_api_key(host: host.to_s, key: key.to_s)
    end
  end

  def list_command
    hosts = Gem::Keychain.list_api_keys
    if hosts.empty?
      alert "No api keys found in the Keychain"
      terminate_interaction(0)
    end

    # Make sure rubygems is always at the top
    if hosts.delete("rubygems")
      say "- rubygems (https://rubygems.org)"
    end

    hosts.sort.each do |host|
      say "- #{host}"
    end
  end

  def add_command
    unless host = options[:args].shift
      host = ask("Name/host:")
    end

    if Gem::Keychain.has_api_key?(host: host)
      alert_error "There is already an api key for '#{host}' in keychain. Remove it first to replace."
      terminate_interaction(1)
    end

    unless key = options[:args].shift
      key = ask_for_password("API Key:")
    end

    Gem::Keychain.set_api_key(host: host, key: key)
    alert "Successfully added key for '#{host}'"
  end

  def rm_command
    unless host = options[:args].shift
      hosts = Gem::Keychain.list_api_keys
      if hosts.empty?
        alert_error "There are no api keys to remove"
        terminate_interaction(1)
      end

      # Make sure rubygems is always at the top
      if hosts.delete("rubygems")
        hosts.unshift("rubygems (rubygems.org)")
      end

      host, index = choose_from_list("Which api key do you want to remove?", hosts)

      unless index.between?(0, hosts.size - 1)
        alert_error "Please enter a number [1-#{hosts.size}]"
        terminate_interaction(1)
      end

      if host == "rubygems (rubygems.org)"
        host = "rubygems"
      end
    end

    unless Gem::Keychain.has_api_key?(host: host)
      alert_error "No such api key '#{host}'."
      terminate_interaction(1)
    end

    unless options[:force]
      if !tty?
        alert_error "Not removing api key without confirmation (override with --force)"
        terminate_interaction(1)
      elsif !ask_yes_no("Are you sure you want to remove the api key '#{host}'?", false)
        alert "Not removing api key"
        terminate_interaction(1)
      end
    end

    Gem::Keychain.rm_api_key(host: host)
    alert "Successfully removed api key '#{host}'"
  end
end
