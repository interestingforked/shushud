class Provider < Sequel::Model

  def self.auth?(id, token)
    provider = Provider[id] || raise(Shushu::NotFound, "Unable to find provider id=#{id}")
    provider[:token] == enc(token)
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
    self[:root]
  end

end
