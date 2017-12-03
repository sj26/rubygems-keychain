# frozen_string_literal: true

require "rubygems"
require "rubygems/keychain/version"

require "open3"
require "openssl"

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

    def add_api_key(host: nil, key:)
      command = [HELPER, "add-api-key"]
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

    def has_key?
      command = [HELPER, "has-key"]

      _, stderr, status = Open3.capture3(*command)

      if status.success?
        true
      elsif status.exitstatus == 1
        false
      else
        raise HelperError.new(stderr.chomp)
      end
    end

    def get_cert
      command = [HELPER, "get-cert"]

      stdout, stderr, status = Open3.capture3(*command, stdin_data: data, binmode: true)

      if status.success?
        stdout
      else
        raise HelperError.new(stderr.chomp)
      end

    def sign(data:)
      command = [HELPER, "sign"]

      stdout, stderr, status = Open3.capture3(*command, stdin_data: data, binmode: true)

      if status.success?
        stdout
      else
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
      Gem::Keychain.add_api_key(host: host, key: key)
    end

    def rubygems_api_key
      Gem::Keychain.get_api_key
    end

    def rubygems_api_key=(key)
      Gem::Keychain.add_api_key(key: key)
    end
  end

  module SignerExtensions
    # We want to intecept calls to Gem::Security::Signer.new(...) and return a
    # Gem::Keychain::Signer instead for the default case.
    def new(key, cert, passphrase=nil)
      # If we've been asked for the default key/cert and we have one in the
      # keychain then use our Signer.
      if key == nil && cert == nil && Gem::Keychain.has_key?
        Gem::Keychain::Signer.new
      else
        super
      end
    end
  end

  # Signer quacks like Gem::Security::Signer, but uses the Keychain
  #
  # The private key lives in Keychain and is never loaded in ruby. Signatures
  # are done by piping the data through the helper.
  #
  # The certificate chain is expected to be a single self-signed certificate
  # with a subject (not alt name). The helper takes care of re-generating the
  # certificate when it expires.
  #
  class Signer
    def key
      # This is used by Gem::Package::TarWriter#add_file_signed to decide
      # whether to sign. It just has to be truthy.
      true
    end

    def cert
      @cert ||= OpenSSL::X509::Certificate.new(Gem::Keychain.get_cert)
    end

    def cert_chain
      [cert]
    end

    def digest_algorithm
      OpenSSL::Digest::SHA1
    end

    def digest_name
      # OpenSSL::Digest::SHA1.new.name
      "SHA1"
    end

    def sign(data)
      # Verifying doesn't seem stricly neccessary, but we'll play ball. Except
      # that we don't supply a key.
      Gem::Security::SigningPolicy.verify(cert_chain, nil, {}, {}, cert.subject)

      Gem::Keychain.sign(data)
    end
  end
end
