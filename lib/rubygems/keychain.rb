# frozen_string_literal: true

require "rubygems"
require "rubygems/keychain/version"

require "open3"

module Gem::Keychain
  HELPER = File.expand_path("../../../libexec/helper", __FILE__)

  class HelperError < RuntimeError; end

  class << self
    def has_api_key?(host: nil)
      command = [HELPER, "has-api-key"]
      command << host if host = sanitize_host(host)

      _, stderr, status = Open3.capture3(*command)

      if status.success?
        true
      elsif status.exitstatus == 1 # not found
        false
      else
        raise HelperError.new(stderr.chomp)
      end
    end

    def get_api_key(host: nil)
      command = [HELPER, "get-api-key"]
      command << host if host = sanitize_host(host)

      stdout, stderr, status = Open3.capture3(*command)

      if status.success?
        stdout.chomp
      else
        raise HelperError.new(stderr.chomp)
      end
    end

    def list_api_keys
      command = [HELPER, "list-api-keys"]

      stdout, stderr, status = Open3.capture3(*command)

      if status.success?
        stdout.split("\n").flatten
      else
        raise HelperError.new(stderr.chomp)
      end
    end

    def set_api_key(host: nil, key:)
      command = [HELPER, "set-api-key"]
      command << host if host = sanitize_host(host)

      _, stderr, status = Open3.capture3(*command, stdin_data: key)

      unless status.success?
        raise HelperError.new(stderr.chomp)
      end
    end

    def rm_api_key(host: nil)
      command = [HELPER, "rm-api-key"]
      command << host if host = sanitize_host(host)

      _, stderr, status = Open3.capture3(*command)

      unless status.success?
        raise HelperError.new(stderr.chomp)
      end
    end

    private

    def sanitize_host(host)
      host.to_s unless host.nil? || host.empty? || host.to_s == "rubygems" || host.to_s == "rubygems_api_key"
    end
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
