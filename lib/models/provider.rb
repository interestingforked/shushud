class Provider < Sequel::Model

  def self.auth?(id, token)
    if provider = Provider[id]
      provider[:token] == enc(token)
    else
      false
    end
  end

  def self.enc(token)
    Digest::SHA1.hexdigest(token).encode('UTF-8')
  end

  def reset_token!(token=nil)
    token ||= SecureRandom.hex(32)
    enc_token = self.class.enc(token)
    update(:token => enc_token)
  end

  def root?
    self[:root] == true
  end

end
