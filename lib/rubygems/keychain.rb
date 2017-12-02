# frozen_string_literal: true

require "rubygems"
require "rubygems/keychain/version"

module Gem::Keychain
  HELPER = File.expand_path("../../../libexec/helper", __FILE__)

  def self.has_api_key?(host: nil)
    command = [HELPER, "has-api-key"]
    host = host.to_s if host
    if host && host != "rubygems" && host != "rubygems_api_key"
      command << host
    end

    system(*command, out: :close, err: :close)
  end

  def self.get_api_key(host: nil)
    command = [HELPER, "get-api-key"]
    host = host.to_s if host
    if host && host != "rubygems" && host != "rubygems_api_key"
      command << host
    end

    IO.popen(command, err: :close, &:read).chomp
  end

  def self.list_api_keys
    command = [HELPER, "list-api-keys"]

    IO.popen(command, err: :close, &:read).split("\n").compact
  end

  def self.set_api_key(host: nil, key:)
    command = [HELPER, "set-api-key"]
    host = host.to_s if host
    if host && host != "rubygems" && host != "rubygems_api_key"
      command << host
    end

    IO.popen(command, "w", err: :close) do |io|
      io.write(key)
      io.close
    end

    $?.success?
  end

  def self.rm_api_key?(host: nil)
    command = [HELPER, "rm-api-key"]
    host = host.to_s if host
    if host && host != "rubygems" && host != "rubygems_api_key"
      command << host
    end

    system(*command)
  end

  class ApiKeys
    # Used in Gem::GemcutterUtilities

    def initialize(fallback: nil)
      @fallback = fallback || {}
    end

    def key?(host)
      Gem::Keychain.has_api_key?(host: host) || @fallback.key?(host.to_s)
    end

    def [](host)
      Gem::Keychain.get_api_key(host: host) || @fallback[host.to_s]
    end
  end

  module ConfigFileExtensions
    # Override api key methods with proxy object

    def load_api_keys
      fallback = load_file(credentials_path) if File.exists?(credentials_path)

      @api_keys = Gem::Keychain::ApiKeys.new(fallback: fallback)
    end

    def api_keys
      load_api_keys unless @api_keys
      @api_keys
    end

    def set_api_key(host, key)
      Gem::Keychain.set_api_key(host: host, key: key)
    end

    def rubygems_api_key
      Gem::Keychain.get_api_key
    end

    def rubygems_api_key=(key)
      Gem::Keychain.set_api_key(key: key)
    end
  end
end
