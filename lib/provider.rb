require 'digest'
require 'securerandom'
require 'shushu'

module Shushu
  # @author Ryan Smith
  class Provider < Sequel::Model

    def self.auth?(id, token)
      if provider = Provider[id.to_i]
        provider[:token] == enc(token) and !provider.disabled?
      else
        false
      end
    end

    def self.enc(token)
      Digest::SHA1.hexdigest(token).encode('UTF-8')
    end

    def reset_token!(token=nil)
      log(fn: __method__, provider_id: self[:id]) do
        token ||= SecureRandom.hex(128)
        enc_token = self.class.enc(token)
        update(:token => enc_token)
      end
    end

    def disabled?
      self[:disabled] == true
    end

    def disable!
      log(fn: __method__, provider_id: self[:id]) do
        update(:disabled => true)
      end
    end

    def enable
      log(fn: __method__, provider_id: self[:id]) do
        update(:disabled => false)
      end
    end

    def root?
      self[:root] == true
    end

    def log(data, &blk)
      Scrolls.log({ns: "provider"}.merge(data), &blk)
    end

  end
end
