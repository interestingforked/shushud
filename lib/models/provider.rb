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
    token ||= SecureRandom.hex(128)
    enc_token = self.class.enc(token)
    update(:token => enc_token)
    Log.info("#provider_token_reset provider=#{self[:id]}")
  end

  def disabled?
    self[:disabled] == true
  end

  def disable!
    update(:disabled => true)
    Log.info("#provider_disabled provider=#{self[:id]}")
  end

  def enable
    update(:disabled => false)
    Log.info("#provider_enabled provider=#{self[:id]}")
  end

  def root?
    self[:root] == true
  end

end
